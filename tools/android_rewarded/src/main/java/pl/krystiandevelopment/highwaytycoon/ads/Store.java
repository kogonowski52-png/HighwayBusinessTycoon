package pl.krystiandevelopment.highwaytycoon.ads;

import android.app.Activity;
import androidx.credentials.CredentialManager;
import androidx.credentials.CredentialManagerCallback;
import androidx.credentials.CustomCredential;
import androidx.credentials.GetCredentialRequest;
import androidx.credentials.GetCredentialResponse;
import androidx.credentials.exceptions.GetCredentialException;
import com.android.billingclient.api.BillingClient;
import com.android.billingclient.api.BillingClientStateListener;
import com.android.billingclient.api.BillingFlowParams;
import com.android.billingclient.api.BillingResult;
import com.android.billingclient.api.PendingPurchasesParams;
import com.android.billingclient.api.ProductDetails;
import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.QueryProductDetailsParams;
import com.android.billingclient.api.QueryPurchasesParams;
import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption;
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.regex.Pattern;

final class Store {
    private static final int OK = BillingClient.BillingResponseCode.OK;
    private static final Pattern PRODUCT = Pattern.compile("[a-z0-9_]{2,64}");
    private static final Pattern ACCOUNT = Pattern.compile("[a-f0-9]{64}");
    private final HighwayRewarded bridge;
    private final Map<String, ProductDetails> products = new ConcurrentHashMap<>();
    private final AtomicBoolean checkout = new AtomicBoolean();
    private final AtomicBoolean identity = new AtomicBoolean();
    private volatile BillingClient client;
    private List<QueryProductDetailsParams.Product> ids = java.util.Collections.emptyList();
    private volatile boolean connecting;
    private volatile boolean connectionAttempted;
    private boolean queryingCatalog;
    private int catalogGeneration;

    Store(HighwayRewarded bridge) { this.bridge = bridge; }
    boolean checkoutOpen() { return checkout.get() || identity.get(); }
    String diagnosticStatus() {
        final BillingClient connected = client;
        return connected != null && connected.isReady() ? "ready"
                : connecting ? "loading" : connectionAttempted ? "failed" : "idle";
    }

    void close() {
        if (client != null) {
            client.endConnection();
            client = null;
        }
        products.clear();
        queryingCatalog = false;
        catalogGeneration++;
        connecting = false;
        checkout.set(false);
        identity.set(false);
    }

    void connect(String input) {
        Activity host = bridge.activity();
        if (host == null) {
            state("connect", BillingClient.BillingResponseCode.SERVICE_DISCONNECTED);
            return;
        }
        host.runOnUiThread(() -> {
            var requested = new ArrayList<QueryProductDetailsParams.Product>();
            for (String product : input.split(",", 40)) {
                if (PRODUCT.matcher(product).matches()) requested.add(QueryProductDetailsParams.Product.newBuilder()
                    .setProductId(product).setProductType(BillingClient.ProductType.INAPP).build());
            }
            ids = requested;
            ensureConnection(host, true);
        });
    }

    void restore() {
        Activity host = bridge.activity();
        if (host != null) host.runOnUiThread(() -> ensureConnection(host, false));
    }

    private void ensureConnection(Activity host, boolean wantsCatalog) {
        if (client != null && client.isReady()) {
            if (wantsCatalog) queryCatalog();
            queryPurchases();
            return;
        }
        if (connecting) return;
        connecting = true;
        connectionAttempted = true;
        if (client == null) {
            client = BillingClient.newBuilder(host.getApplicationContext())
                .setListener((result, purchases) -> {
                    checkout.set(false);
                    state("purchase", result.getResponseCode());
                    if (purchases != null) sendPurchases(purchases, false);
                })
                .enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().build())
                .enableAutoServiceReconnection()
                .build();
        }
        client.startConnection(new BillingClientStateListener() {
            @Override public void onBillingSetupFinished(BillingResult result) {
                connecting = false;
                state("connect", result.getResponseCode());
                if (result.getResponseCode() == OK) {
                    queryCatalog();
                    queryPurchases();
                }
            }
            @Override public void onBillingServiceDisconnected() {
                connecting = false;
                checkout.set(false);
                queryingCatalog = false;
                catalogGeneration++;
                products.clear();
                state("disconnect", BillingClient.BillingResponseCode.SERVICE_DISCONNECTED);
            }
        });
    }

    private void queryCatalog() {
        if (ids.isEmpty() || queryingCatalog) return;
        queryingCatalog = true;
        int generation = ++catalogGeneration;
        client.queryProductDetailsAsync(QueryProductDetailsParams.newBuilder().setProductList(ids).build(), (response, result) -> {
            if (generation != catalogGeneration) return;
            queryingCatalog = false;
            products.clear();
            if (response.getResponseCode() != OK) {
                state("catalog", response.getResponseCode());
                return;
            }
            var payload = new JSONObject();
            for (ProductDetails product : result.getProductDetailsList()) {
                var selected = baseOffer(product);
                if (selected == null) continue;
                products.put(product.getProductId(), product);
                try {
                    payload.put(product.getProductId(), new JSONObject().put("price", selected.getFormattedPrice())
                        .put("currency", selected.getPriceCurrencyCode()));
                } catch (JSONException ignored) { }
            }
            bridge.dispatch("billing_catalog", payload.toString());
            state("catalog", response.getResponseCode());
        });
    }

    private ProductDetails.OneTimePurchaseOfferDetails baseOffer(ProductDetails product) {
        var offers = product.getOneTimePurchaseOfferDetailsList();
        if (offers != null) for (var offer : offers) {
            if ((offer.getOfferId() == null || offer.getOfferId().isEmpty())
                    && offer.getRentalDetails() == null && offer.getPreorderDetails() == null) return offer;
        }
        return null;
    }

    private void queryPurchases() {
        client.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.INAPP).build(), (result, purchases) -> {
            state("restore", result.getResponseCode());
            if (result.getResponseCode() == OK) sendPurchases(purchases, true);
        });
    }

    private void sendPurchases(List<Purchase> purchases, boolean snapshot) {
        var payload = new JSONArray();
        for (Purchase purchase : purchases) {
            if (purchase.getProducts().size() != 1) continue;
            try {
                payload.put(new JSONObject().put("product", purchase.getProducts().get(0))
                    .put("token", purchase.getPurchaseToken()).put("state", purchase.getPurchaseState()));
            } catch (JSONException ignored) { }
        }
        try {
            bridge.dispatch("billing_purchases", snapshot
                ? new JSONObject().put("owned", payload).toString() : payload.toString());
        } catch (JSONException ignored) { }
    }

    boolean launch(String id, String account) {
        Activity host = bridge.activity();
        ProductDetails product = products.get(id);
        if (host == null || product == null || !ACCOUNT.matcher(account).matches() || !checkout.compareAndSet(false, true)) return false;
        host.runOnUiThread(() -> {
            if (client == null || !client.isReady()) {
                checkout.set(false);
                state("purchase", BillingClient.BillingResponseCode.SERVICE_DISCONNECTED);
                return;
            }
            var offer = baseOffer(product);
            if (offer == null) {
                checkout.set(false);
                state("purchase", BillingClient.BillingResponseCode.ITEM_UNAVAILABLE);
                return;
            }
            var params = BillingFlowParams.ProductDetailsParams.newBuilder()
                .setProductDetails(product).setOfferToken(offer.getOfferToken()).build();
            BillingResult result = client.launchBillingFlow(host, BillingFlowParams.newBuilder()
                .setObfuscatedAccountId(account).setProductDetailsParamsList(java.util.Collections.singletonList(params)).build());
            if (result.getResponseCode() != OK) {
                checkout.set(false);
                state("purchase", result.getResponseCode());
                if (result.getResponseCode() == BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED) queryPurchases();
            }
        });
        return true;
    }

    boolean identify(String clientId, String nonce) {
        Activity host = bridge.activity();
        if (host == null || !ACCOUNT.matcher(nonce).matches() || checkout.get() || !identity.compareAndSet(false, true)) return false;
        host.runOnUiThread(() -> {
            var option = new GetSignInWithGoogleOption.Builder(clientId).setNonce(nonce).build();
            var request = new GetCredentialRequest.Builder().addCredentialOption(option).build();
            CredentialManager.create(host).getCredentialAsync(host, request, null, host::runOnUiThread,
                new CredentialManagerCallback<GetCredentialResponse, GetCredentialException>() {
                    @Override public void onResult(GetCredentialResponse result) {
                        String token = "";
                        try {
                            if (result.getCredential() instanceof CustomCredential credential) {
                                token = GoogleIdTokenCredential.createFrom(credential.getData()).getIdToken();
                            }
                        } catch (Exception ignored) { }
                        identity.set(false);
                        bridge.dispatch("identity_result", token);
                    }
                    @Override public void onError(GetCredentialException error) {
                        identity.set(false);
                        bridge.dispatch("identity_result", "");
                    }
                });
        });
        return true;
    }

    private void state(String source, int code) { bridge.dispatch("billing_state", source, code); }
}
