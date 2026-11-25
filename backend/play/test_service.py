import json
import tempfile
import unittest
from io import BytesIO
from pathlib import Path

from service import ApiError, CONSUMABLE, Service, digest

TOKEN = "verified_purchase_receipt_123456"
ACCOUNT = "a" * 64
INSTALL = "e" * 32
OTHER = "f" * 32
UTC = 1795392000


class PublisherFixture:
    def __init__(self):
        self.documents = {}
        self.statements = []
        self.revoked = []
        self.finalization_fault = False

    def verify_identity(self, token):
        return {"nonce": token, "sub": "synthetic-user-123"}

    def get(self, token):
        return self.documents[token]

    def finalize(self, token, product, consume):
        self.statements.append((token, product, consume))
        if consume:
            self.documents[token]["productLineItem"][0]["productOfferDetails"]["consumptionState"] = "CONSUMPTION_STATE_CONSUMED"
        else:
            self.documents[token]["acknowledgementState"] = "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED"
        if self.finalization_fault:
            raise ConnectionError("Test finalization timed out after Play accepted it")

    def voids(self, _):
        return iter(self.revoked)

    def proof(self, product, account=ACCOUNT, state="PURCHASED"):
        self.documents[TOKEN] = {"obfuscatedExternalAccountId": account,
            "purchaseStateContext": {"purchaseState": state},
            "productLineItem": [{"productId": product, "productOfferDetails": {"quantity": 1}}]}


class StoreTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.google = PublisherFixture()
        self.store = Service(Path(self.directory.name) / "test.db", b"U" * 32, self.google, clock=lambda: UTC)

    def deliver(self, product, account=ACCOUNT, install=INSTALL):
        return self.store.receipt(account, {"token": TOKEN, "install": install, "product": product})

    def test_consumable_once_only_on_original_save(self):
        self.google.proof("gems_550")
        result = self.deliver("gems_550")
        self.assertEqual(result["grants"], [{"id": digest(TOKEN), "product": "gems_550"}])
        self.assertEqual(result, self.deliver("gems_550"))
        self.assertEqual(self.deliver("gems_550", install=OTHER)["grants"], [])
        self.assertEqual([(TOKEN, "gems_550", True)], self.google.statements)

    def test_refunded_durable_invokes_restore_without_consuming(self):
        self.google.proof("remove_ads")
        self.deliver("remove_ads")
        self.assertEqual(self.store.sync(ACCOUNT, OTHER)["entitlements"], ["remove_ads"])
        self.assertEqual([(TOKEN, "remove_ads", False)], self.google.statements)
        self.google.revoked.append({"purchaseToken": TOKEN})
        self.assertEqual(self.store.reconcile(14), 1)
        self.assertEqual(self.store.sync(ACCOUNT, OTHER)["entitlements"], [])
        with self.assertRaisesRegex(ApiError, "voided"):
            self.deliver("remove_ads")

    def test_wrong_account_and_pending_cannot_grant(self):
        self.google.proof("starter_pack", state="PENDING")
        with self.assertRaisesRegex(ApiError, "pending"):
            self.deliver("starter_pack")
        self.google.proof("starter_pack", "other")
        with self.assertRaisesRegex(ApiError, "account_mismatch"):
            self.deliver("starter_pack")
        self.assertEqual(self.store.sync(ACCOUNT, INSTALL)["grants"], [])
        self.assertEqual(self.google.statements, [])

    def test_test_purchase_and_wrong_sku_rejected(self):
        self.google.proof("gems_550")
        with self.assertRaisesRegex(ApiError, "invalid_product"):
            self.deliver("gems_100")
        self.google.documents[TOKEN]["testPurchaseContext"] = {"fopType": "TEST"}
        with self.assertRaisesRegex(ApiError, "test_purchase"):
            self.deliver("gems_550")

    def test_lost_response_and_durable_ack_queue(self):
        self.google.proof("gems_100")
        self.google.finalization_fault = True
        with self.assertRaises(ConnectionError):
            self.deliver("gems_100")
        with self.store.db() as connection:
            stored = connection.execute("SELECT cipher FROM pending_finish").fetchone()[0]
            self.assertNotIn(TOKEN.encode(), stored)
        self.google.finalization_fault = False
        self.assertEqual(self.store.retry_finalization(), 1)
        self.assertEqual(len(self.store.sync(ACCOUNT, INSTALL)["grants"]), 1)
        self.assertEqual(len(self.google.statements), 1)

    def test_void_before_purchase_is_a_tombstone(self):
        self.google.revoked.append({"purchaseToken": TOKEN})
        self.store.reconcile(15)
        self.google.proof("starter_pack")
        with self.assertRaisesRegex(ApiError, "voided"):
            self.deliver("starter_pack")
        self.assertEqual(self.google.statements, [])

    def test_signed_session_and_single_use_nonce(self):
        nonce = self.store.challenge()["nonce"]
        values = self.store.login({"id_token": nonce, "nonce": nonce})
        self.assertEqual(self.store.authorized("Bearer " + values["session"]), values["account"])
        with self.assertRaisesRegex(ApiError, "identity_required"):
            self.store.login({"id_token": nonce, "nonce": nonce})
        with self.assertRaisesRegex(ApiError, "identity_required"):
            self.store.authorized("Bearer " + "X" * 43)

    def test_http_enforces_account_and_body_limit(self):
        statuses = []
        body = json.dumps({"install": INSTALL}).encode()
        result = self.store.wsgi({"PATH_INFO": "/v1/sync", "REQUEST_METHOD": "POST",
            "CONTENT_LENGTH": len(body), "wsgi.input": BytesIO(body)}, lambda state, headers: statuses.append(state))
        self.assertTrue(statuses[0].startswith("401"))
        self.assertNotIn(b"session", b"".join(result))

    def test_unknown_consumed_item_is_not_reissued(self):
        item = sorted(CONSUMABLE)[0]
        self.google.proof(item)
        self.google.finalize(TOKEN, item, True)
        with self.assertRaisesRegex(ApiError, "consumed_without_grant"):
            self.deliver(item)


if __name__ == "__main__":
    unittest.main()
