"""Play one-time purchase verification and delivery. Run behind HTTPS."""
from contextlib import contextmanager
from base64 import urlsafe_b64encode
import hashlib
import hmac
import json
import logging
import os
import re
import secrets
import sqlite3
import time
from pathlib import Path
from urllib.parse import quote

PACKAGE = "pl.krystiandevelopment.highwaytycoon"
API = f"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PACKAGE}/purchases"
CONSUMABLE = {"gems_100", "gems_550", "gems_1200", "gems_2500", "gems_6500"}
PRODUCTS = CONSUMABLE | {
    "starter_pack", "remove_ads", "manager_pack", "builder_pack", "workshop_pack",
    "wash_pack", "freight_pack", "coast_pack", "season_pass_2026_snow",
    "season_pass_2026_holiday", "season_pass_2026_sport", "season_pass_2027_truck",
    "season_pass_2027_summer", "season_pass_2027_green",
}
TOKEN = re.compile(r"[A-Za-z0-9_.~/+=-]{16,4096}\Z")
INSTALL = re.compile(r"[0-9a-f]{32}\Z")
NONCE = re.compile(r"[0-9a-f]{64}\Z")
DAY = 86_400
FINALIZATION_LEASE = 90
RETRY_DELAY = 30 * 60
LOG = logging.getLogger("hbt.play")


class ApiError(Exception):
    def __init__(self, status: int, code: str):
        self.status, self.code = status, code


def digest(value: str) -> str:
    return hashlib.sha256(value.encode()).hexdigest()


def text(data: dict, field: str, pattern: re.Pattern) -> str:
    value = data.get(field)
    if not isinstance(value, str) or not pattern.fullmatch(value):
        raise ApiError(400, "invalid_request")
    return value


class Google:
    def __init__(self, audience: str):
        import google.auth
        from google.auth.transport.requests import AuthorizedSession, Request
        from google.oauth2 import id_token

        credentials, _ = google.auth.default(scopes=["https://www.googleapis.com/auth/androidpublisher"])
        self.publisher = AuthorizedSession(credentials)
        self.verify_identity = lambda token: id_token.verify_oauth2_token(token, Request(), audience)

    def get(self, token: str) -> dict:
        response = self.publisher.get(f"{API}/productsv2/tokens/{quote(token, safe='')}", timeout=12)
        if response.status_code in (400, 404, 410):
            raise ApiError(422, "unverified")
        response.raise_for_status()
        return response.json()

    def finalize(self, token: str, product: str, consume: bool) -> None:
        action = "consume" if consume else "acknowledge"
        url = f"{API}/products/{quote(product, safe='')}/tokens/{quote(token, safe='')}:{action}"
        self.publisher.post(url, json={}, timeout=12).raise_for_status()

    def voids(self, start_ms: int):
        query = {"startTime": start_ms, "type": 0, "maxResults": 200}
        while True:
            response = self.publisher.get(f"{API}/voidedpurchases", params=query, timeout=12)
            response.raise_for_status()
            page = response.json()
            yield from page.get("voidedPurchases", [])
            token = page.get("tokenPagination", {}).get("nextPageToken")
            if not token:
                break
            query["token"] = token


class Service:
    def __init__(self, path: Path, secret: bytes, google, allow_test: bool = False, clock=time.time):
        if len(secret) < 32:
            raise ValueError("HBT_ACCOUNT_SECRET requires at least 32 bytes")
        from cryptography.fernet import Fernet

        self.path, self.secret, self.google, self.allow_test, self.clock = path, secret, google, allow_test, clock
        self.queue_cipher = Fernet(urlsafe_b64encode(hmac.digest(secret, b"hbt-play-finalization-v1", "sha256")))
        path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        fd = os.open(path, os.O_CREAT | os.O_RDWR, 0o600)
        os.close(fd)
        with self.db() as db:
            db.execute("PRAGMA journal_mode=WAL")
            db.executescript("""
                CREATE TABLE IF NOT EXISTS nonce (
                    key TEXT PRIMARY KEY, expires INTEGER NOT NULL
                );
                CREATE INDEX IF NOT EXISTS nonce_expiry ON nonce(expires);
                CREATE TABLE IF NOT EXISTS session (
                    key TEXT PRIMARY KEY, account TEXT NOT NULL, expires INTEGER NOT NULL
                );
                CREATE INDEX IF NOT EXISTS session_expiry ON session(expires);
                CREATE TABLE IF NOT EXISTS receipt (
                    id TEXT PRIMARY KEY, account TEXT NOT NULL, install TEXT NOT NULL,
                    product TEXT NOT NULL, state TEXT NOT NULL, finalized INTEGER NOT NULL DEFAULT 0,
                    created INTEGER NOT NULL
                );
                CREATE INDEX IF NOT EXISTS receipt_account ON receipt(account);
                CREATE TABLE IF NOT EXISTS pending_finish (
                    id TEXT PRIMARY KEY, cipher BLOB NOT NULL, next_try INTEGER NOT NULL DEFAULT 0
                );
            """)

    @contextmanager
    def db(self):
        conn = sqlite3.connect(self.path, timeout=12)
        conn.row_factory = sqlite3.Row
        try:
            with conn:
                yield conn
        finally:
            conn.close()

    def challenge(self) -> dict:
        nonce, now = secrets.token_hex(32), int(self.clock())
        with self.db() as db:
            db.execute("BEGIN IMMEDIATE")
            db.execute("DELETE FROM nonce WHERE expires < ?", (now,))
            db.execute("INSERT INTO nonce VALUES (?, ?)", (digest(nonce), now + 300))
        return {"nonce": nonce}

    def login(self, data: dict) -> dict:
        nonce = text(data, "nonce", NONCE)
        token = data.get("id_token")
        if not isinstance(token, str) or not 32 <= len(token) <= 8192:
            raise ApiError(401, "identity_required")
        nonce_key = digest(nonce)
        with self.db() as db:
            if db.execute("SELECT 1 FROM nonce WHERE key=? AND expires>=?", (nonce_key, int(self.clock()))).fetchone() is None:
                raise ApiError(401, "identity_required")
        try:
            identity = self.google.verify_identity(token)
        except ValueError:
            raise ApiError(401, "identity_required") from None
        subject = identity.get("sub")
        if not isinstance(subject, str) or not subject or identity.get("nonce") != nonce:
            raise ApiError(401, "identity_required")
        account = hmac.new(self.secret, subject.encode(), hashlib.sha256).hexdigest()
        bearer, now = secrets.token_urlsafe(32), int(self.clock())
        with self.db() as db:
            db.execute("BEGIN IMMEDIATE")
            deleted = db.execute("DELETE FROM nonce WHERE key=? AND expires>=?", (nonce_key, now))
            if deleted.rowcount != 1:
                raise ApiError(401, "identity_required")
            db.execute("DELETE FROM session WHERE expires < ?", (now,))
            db.execute("INSERT INTO session VALUES (?, ?, ?)", (digest(bearer), account, now + 8 * 3600))
        return {"session": bearer, "account": account}

    def authorized(self, header: str) -> str:
        token = header.removeprefix("Bearer ")
        if not header.startswith("Bearer ") or len(token) != 43:
            raise ApiError(401, "identity_required")
        with self.db() as db:
            row = db.execute("SELECT account FROM session WHERE key=? AND expires>=?", (digest(token), int(self.clock()))).fetchone()
        if row is None:
            raise ApiError(401, "identity_required")
        return row["account"]

    def verified_product(self, proof: dict, product: str, account: str) -> dict:
        external = proof.get("obfuscatedExternalAccountId", "")
        if not isinstance(external, str) or not hmac.compare_digest(external, account):
            raise ApiError(409, "account_mismatch")
        if "testPurchaseContext" in proof and not self.allow_test:
            raise ApiError(422, "test_purchase")
        state = proof.get("purchaseStateContext", {}).get("purchaseState")
        if state == "PENDING":
            raise ApiError(409, "pending")
        if state != "PURCHASED":
            raise ApiError(422, "unverified")
        lines = proof.get("productLineItem", [])
        if len(lines) != 1 or lines[0].get("productId") != product:
            raise ApiError(422, "invalid_product")
        details = lines[0].get("productOfferDetails", {})
        if details.get("quantity", 1) != 1 or details.get("refundableQuantity", 1) != 1 or "rentOfferDetails" in details:
            raise ApiError(422, "invalid_quantity")
        return details

    def receipt(self, account: str, data: dict) -> dict:
        token = text(data, "token", TOKEN)
        install = text(data, "install", INSTALL)
        product = data.get("product")
        if not isinstance(product, str) or product not in PRODUCTS:
            raise ApiError(400, "invalid_product")
        rid = digest(token)
        with self.db() as db:
            existing = db.execute("SELECT account, product, state, finalized FROM receipt WHERE id=?", (rid,)).fetchone()
            if existing and existing["state"] == "void":
                raise ApiError(410, "voided")
            if existing and (existing["account"] != account or existing["product"] != product):
                raise ApiError(409, "account_mismatch")
            if existing and existing["finalized"]:
                return self.sync(account, install)

        proof = self.google.get(token)
        details = self.verified_product(proof, product, account)
        consumed = details.get("consumptionState") == "CONSUMPTION_STATE_CONSUMED"
        acknowledged = proof.get("acknowledgementState") == "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED"
        consumable = product in CONSUMABLE
        needs_finalization = not (consumed if consumable else acknowledged)
        lease = False
        with self.db() as db:
            db.execute("BEGIN IMMEDIATE")
            entry = db.execute("SELECT account, product, state, finalized FROM receipt WHERE id=?", (rid,)).fetchone()
            if entry:
                if entry["state"] == "void":
                    raise ApiError(410, "voided")
                if entry["account"] != account or entry["product"] != product:
                    raise ApiError(409, "account_mismatch")
                if entry["finalized"]:
                    needs_finalization = False
            else:
                if consumed:
                    raise ApiError(409, "consumed_without_grant")
                if not consumable and db.execute(
                    "SELECT id FROM receipt WHERE account=? AND product=? AND state='purchased'", (account, product)
                ).fetchone():
                    raise ApiError(409, "already_owned")
                db.execute("INSERT INTO receipt VALUES (?, ?, ?, ?, 'purchased', 0, ?)",
                           (rid, account, install, product, int(self.clock())))
            if needs_finalization:
                db.execute("INSERT OR IGNORE INTO pending_finish(id,cipher) VALUES (?,?)",
                           (rid, self.queue_cipher.encrypt(token.encode())))
                now = int(self.clock())
                lease = self.lease_finalization(db, rid, now, FINALIZATION_LEASE)

        # Commit a durable intent before talking to Play. A staged receipt cannot grant anything.
        if needs_finalization:
            if not lease:
                raise ApiError(503, "temporarily_unavailable")
            try:
                self.google.finalize(token, product, consumable)
            except Exception:
                # Network and Publisher errors leave an encrypted retry but no client entitlement.
                LOG.warning("Purchase finalization deferred")
                raise
        self.complete(rid)
        return self.sync(account, install)

    @staticmethod
    def lease_finalization(db: sqlite3.Connection, rid: str, now: int, seconds: int) -> bool:
        changed = db.execute("UPDATE pending_finish SET next_try=? WHERE id=? AND next_try<=?",
                             (now + seconds, rid, now)).rowcount
        return changed == 1

    def prune_auth(self) -> None:
        now = int(self.clock())
        with self.db() as db:
            db.execute("DELETE FROM nonce WHERE expires<?", (now,))
            db.execute("DELETE FROM session WHERE expires<?", (now,))

    def monitor(self) -> dict:
        with self.db() as db:
            queue = db.execute("SELECT COUNT(*), MIN(receipt.created) FROM pending_finish JOIN receipt USING(id)").fetchone()
        age = max(0, int(self.clock()) - queue[1]) if queue[1] is not None else 0
        return {"pending_finalization": queue[0], "oldest_pending_seconds": age}

    def complete(self, rid: str) -> None:
        with self.db() as db:
            db.execute("UPDATE receipt SET finalized=1 WHERE id=?", (rid,))
            db.execute("DELETE FROM pending_finish WHERE id=?", (rid,))

    def retry_finalization(self) -> int:
        self.prune_auth()
        now = int(self.clock())
        with self.db() as db:
            items = db.execute("""
                SELECT receipt.id, receipt.product, receipt.account, pending_finish.cipher
                FROM pending_finish JOIN receipt USING (id)
                WHERE receipt.state='purchased' AND pending_finish.next_try<=?
                ORDER BY pending_finish.next_try LIMIT 140
            """, (now,)).fetchall()
        count = 0
        deferred = 0
        for item in items:
            product, rid = item["product"], item["id"]
            with self.db() as db:
                if not self.lease_finalization(db, rid, now, RETRY_DELAY):
                    continue
            try:
                token = self.queue_cipher.decrypt(item["cipher"]).decode()
                proof = self.google.get(token)
                details = self.verified_product(proof, product, item["account"])
                consumable = product in CONSUMABLE
                finished = details.get("consumptionState") == "CONSUMPTION_STATE_CONSUMED" if consumable else (
                    proof.get("acknowledgementState") == "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED"
                )
                if not finished:
                    self.google.finalize(token, product, consumable)
                self.complete(rid)
                count += 1
            except Exception:
                # Retry metadata stays in the database. Client libraries may include the token in exceptions.
                deferred += 1
        if deferred:
            LOG.warning("Deferred finalizations in maintenance: %d", deferred)
        return count

    def sync(self, account: str, install: str) -> dict:
        with self.db() as db:
            rows = db.execute("SELECT id, install, product FROM receipt WHERE account=? AND state='purchased' AND finalized=1 ORDER BY created, id",
                              (account,)).fetchall()
        return {"account": account,
                "entitlements": sorted({r["product"] for r in rows if r["product"] not in CONSUMABLE}),
                "grants": [{"id": r["id"], "product": r["product"]} for r in rows if r["install"] == install]}

    def reconcile(self, span_days: int) -> int:
        since = int((self.clock() - min(29, max(1, span_days)) * DAY) * 1000)
        count = 0
        for revoked in self.google.voids(since):
            token = revoked.get("purchaseToken")
            if isinstance(token, str) and TOKEN.fullmatch(token):
                # A void can arrive before a delayed Billing callback. Keep the tombstone.
                with self.db() as db:
                    db.execute("BEGIN IMMEDIATE")
                    count += db.execute("""
                        INSERT INTO receipt VALUES (?, '', '', '', 'void', 1, ?)
                        ON CONFLICT(id) DO UPDATE SET state='void' WHERE state!='void'
                    """, (digest(token), int(self.clock()))).rowcount
                    db.execute("DELETE FROM pending_finish WHERE id=?", (digest(token),))
        return count

    def wsgi(self, env, start):
        try:
            path = env.get("PATH_INFO", "")
            if env.get("REQUEST_METHOD") == "GET" and path == "/health":
                with self.db() as db:
                    db.execute("SELECT id FROM receipt LIMIT 1").fetchone()
                body = {"status": "ready", "mode": "sandbox" if self.allow_test else "production"}
            elif env.get("REQUEST_METHOD") != "POST":
                raise ApiError(404, "unknown_route")
            else:
                count = int(env.get("CONTENT_LENGTH") or 0)
                if not 0 < count <= 16_384:
                    raise ApiError(400, "invalid_request")
                data = json.loads(env["wsgi.input"].read(count))
                if not isinstance(data, dict):
                    raise ApiError(400, "invalid_request")
                if path == "/v1/challenge":
                    body = self.challenge()
                elif path == "/v1/session":
                    body = self.login(data)
                else:
                    owner = self.authorized(env.get("HTTP_AUTHORIZATION", ""))
                    if path == "/v1/receipt":
                        body = self.receipt(owner, data)
                    elif path == "/v1/sync":
                        body = self.sync(owner, text(data, "install", INSTALL))
                    else:
                        raise ApiError(404, "unknown_route")
            code = 200
        except ApiError as error:
            code, body = error.status, {"error": error.code}
        except (ValueError, UnicodeError):
            code, body = 400, {"error": "invalid_request"}
        except Exception as error:
            # Error details can contain a receipt token in the Publisher request URL.
            LOG.warning("Verifier operation unavailable (%s)", type(error).__name__)
            code, body = 503, {"error": "temporarily_unavailable"}
        status = {200: "OK", 400: "Bad Request", 401: "Unauthorized", 404: "Not Found", 409: "Conflict",
                  410: "Gone", 422: "Unprocessable Entity", 503: "Service Unavailable"}[code]
        output = json.dumps(body, separators=(",", ":")).encode()
        start(f"{code} {status}", [("Content-Type", "application/json"), ("Content-Length", str(len(output))),
                                    ("Cache-Control", "no-store")])
        return [output]


def from_environment():
    audience = os.environ["HBT_GOOGLE_CLIENT_ID"]
    credential_dir = os.environ.get("CREDENTIALS_DIRECTORY")
    if credential_dir:
        root = Path(credential_dir)
        secret = (root / "account").read_bytes().strip()
        os.environ.setdefault("GOOGLE_APPLICATION_CREDENTIALS", str(root / "google.json"))
    else:
        secret = os.environ["HBT_ACCOUNT_SECRET"].encode()
    return Service(Path(os.environ["HBT_PLAY_DB"]), secret, Google(audience), os.environ.get("HBT_PLAY_TEST") == "1")


def make_app():
    return from_environment().wsgi


if __name__ == "__main__":
    import argparse
    from wsgiref.simple_server import make_server

    args = argparse.ArgumentParser()
    args.add_argument("action", choices=["serve", "reconcile", "retry", "monitor"])
    args.add_argument("--port", type=int, default=8074)
    args.add_argument("--days", type=int, default=14)
    command = args.parse_args()
    service = from_environment()
    if command.action in ("reconcile", "retry", "monitor"):
        try:
            if command.action == "reconcile":
                print(f"Voided receipts reconciled: {service.reconcile(command.days)}")
            elif command.action == "retry":
                print(f"Receipts finalized: {service.retry_finalization()}")
            else:
                print(json.dumps(service.monitor(), separators=(",", ":")))
        except Exception as error:
            LOG.error("Verifier maintenance unavailable (%s)", type(error).__name__)
            raise SystemExit(1) from None
    else:
        make_server("127.0.0.1", command.port, service.wsgi).serve_forever()
