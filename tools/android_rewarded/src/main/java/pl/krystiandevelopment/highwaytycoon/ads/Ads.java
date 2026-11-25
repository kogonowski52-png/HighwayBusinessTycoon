package pl.krystiandevelopment.highwaytycoon.ads;

import android.app.Activity;
import android.os.SystemClock;
import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;
import com.google.android.gms.ads.rewarded.RewardedAd;
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback;
import com.google.android.ump.ConsentInformation;
import com.google.android.ump.ConsentRequestParameters;
import com.google.android.ump.UserMessagingPlatform;

import java.util.ArrayList;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicBoolean;

final class Ads {
    private static final String BREAK = "interstitial";
    private static final long EXPIRATION = 50 * 60 * 1000;
    private static final Set<String> PLACEMENTS = new java.util.HashSet<>(java.util.Arrays.asList("boost", "offline", "bonus"));
    private final HighwayRewarded bridge;
    private final Set<String> loading = ConcurrentHashMap.newKeySet();
    private final ConcurrentHashMap<String, Loaded> ready = new ConcurrentHashMap<>();
    private final AtomicBoolean fullscreen = new AtomicBoolean();
    private volatile boolean consentUpdating;
    private boolean consentChecked;
    private boolean initializing;
    private boolean initialized;
    private int generation;
    private volatile boolean privacyRequired;

    private static final class Loaded {
        final Object ad;
        final long expires = SystemClock.elapsedRealtime() + EXPIRATION;
        Loaded(Object ad) { this.ad = ad; }
    }

    Ads(HighwayRewarded bridge) { this.bridge = bridge; }
    boolean fullscreen() { return fullscreen.get(); }
    boolean privacyRequired() { return privacyRequired; }
    boolean rewardLoading(String slot) { return loading.contains(slot); }
    boolean rewardReady(String slot) { return PLACEMENTS.contains(slot) && usable(slot); }
    boolean breakReady() { return usable(BREAK); }

    private boolean usable(String slot) {
        Loaded item = ready.get(slot);
        if (item == null) return false;
        if (SystemClock.elapsedRealtime() < item.expires) return true;
        ready.remove(slot, item);
        return false;
    }

    void prepareReward(String slot) {
        if (PLACEMENTS.contains(slot)) prepare(slot);
    }

    void prepareBreak() { prepare(BREAK); }

    private String unit(String slot) {
        return bridge.config(BREAK.equals(slot) ? BREAK : "rewarded_" + slot);
    }

    private void prepare(String slot) {
        Activity host = bridge.activity();
        if (host == null || fullscreen() || unit(slot).isEmpty() || usable(slot) || !loading.add(slot)) return;
        host.runOnUiThread(() -> consentThenLoad(host));
    }

    private void consentThenLoad(Activity host) {
        if (consentUpdating) return;
        ConsentInformation consent = UserMessagingPlatform.getConsentInformation(host);
        if (consentChecked && consent.canRequestAds()) {
            loadPermitted(host);
            return;
        }
        consentUpdating = true;
        var parameters = new ConsentRequestParameters.Builder().build();
        consent.requestConsentInfoUpdate(host, parameters, () ->
            UserMessagingPlatform.loadAndShowConsentFormIfRequired(host, ignored -> afterConsent(host, consent)),
            failure -> afterConsent(host, consent));
    }

    private void afterConsent(Activity host, ConsentInformation consent) {
        consentUpdating = false;
        consentChecked = true;
        updatePrivacy(consent);
        if (consent.canRequestAds() && bridge.activity() != null) {
            loadPermitted(host);
        } else {
            loading.clear();
            availability();
        }
    }

    private void loadPermitted(Activity host) {
        if (initializing) return;
        if (!initialized) {
            initializing = true;
            MobileAds.initialize(host, result -> host.runOnUiThread(() -> {
                initialized = true;
                initializing = false;
                if (UserMessagingPlatform.getConsentInformation(host).canRequestAds()) loadPermitted(host);
                else { loading.clear(); availability(); }
            }));
            return;
        }
        for (String slot : new ArrayList<>(loading)) load(host, slot);
    }

    private final Set<String> requesting = ConcurrentHashMap.newKeySet();

    private void load(Activity host, String slot) {
        if (!requesting.add(slot)) return;
        int requestGeneration = generation;
        AdRequest request = new AdRequest.Builder().build();
        if (BREAK.equals(slot)) {
            InterstitialAd.load(host, unit(slot), request, new InterstitialAdLoadCallback() {
                @Override public void onAdLoaded(InterstitialAd ad) { loaded(slot, ad, requestGeneration); }
                @Override public void onAdFailedToLoad(LoadAdError problem) { loaded(slot, null, requestGeneration); }
            });
        } else {
            RewardedAd.load(host, unit(slot), request, new RewardedAdLoadCallback() {
                @Override public void onAdLoaded(RewardedAd ad) { loaded(slot, ad, requestGeneration); }
                @Override public void onAdFailedToLoad(LoadAdError problem) { loaded(slot, null, requestGeneration); }
            });
        }
    }

    private void loaded(String slot, Object ad, int requestGeneration) {
        if (generation != requestGeneration) return;
        requesting.remove(slot);
        loading.remove(slot);
        if (ad != null) ready.put(slot, new Loaded(ad));
        availability();
    }

    boolean showRewarded(String slot, String ticket) {
        return PLACEMENTS.contains(slot) && show(slot, ticket);
    }

    boolean showBreak(String ticket) { return show(BREAK, ticket); }

    private boolean show(String slot, String ticket) {
        Activity host = bridge.activity();
        if (host == null || consentUpdating || !usable(slot) || !fullscreen.compareAndSet(false, true)) return false;
        Loaded item = ready.remove(slot);
        boolean isBreak = BREAK.equals(slot);
        host.runOnUiThread(() -> {
            if (item == null || bridge.activity() == null || !UserMessagingPlatform.getConsentInformation(host).canRequestAds()) {
                close(ticket, isBreak);
                return;
            }
            var shown = new AtomicBoolean();
            var awarded = new AtomicBoolean();
            var closed = new AtomicBoolean();
            var callback = new FullScreenContentCallback() {
                @Override public void onAdShowedFullScreenContent() {
                    if (shown.compareAndSet(false, true)) {
                        if (isBreak) bridge.dispatch("break_shown", ticket);
                        else bridge.dispatch("ad_shown", slot);
                    }
                }
                @Override public void onAdDismissedFullScreenContent() {
                    if (closed.compareAndSet(false, true)) close(ticket, isBreak);
                }
                @Override public void onAdFailedToShowFullScreenContent(AdError failure) {
                    if (closed.compareAndSet(false, true)) close(ticket, isBreak);
                }
            };
            try {
                if (isBreak) {
                    InterstitialAd interstitial = (InterstitialAd) item.ad;
                    interstitial.setFullScreenContentCallback(callback);
                    interstitial.show(host);
                } else {
                    RewardedAd reward = (RewardedAd) item.ad;
                    reward.setFullScreenContentCallback(callback);
                    reward.show(host, itemAwarded -> {
                        if (!closed.get() && awarded.compareAndSet(false, true)) bridge.dispatch("reward_earned", ticket);
                    });
                }
            } catch (RuntimeException failure) {
                if (closed.compareAndSet(false, true)) close(ticket, isBreak);
            }
        });
        availability();
        return true;
    }

    private void close(String ticket, boolean isBreak) {
        fullscreen.set(false);
        bridge.dispatch(isBreak ? "break_closed" : "reward_closed", ticket);
        availability();
    }

    private void updatePrivacy(ConsentInformation consent) {
        privacyRequired = consent.getPrivacyOptionsRequirementStatus()
                == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED;
    }

    void privacy() {
        Activity host = bridge.activity();
        if (host == null || !privacyRequired || fullscreen()) return;
        host.runOnUiThread(() -> {
            if (consentUpdating || fullscreen()) return;
            consentUpdating = true;
            generation++;
            ready.clear();
            loading.clear();
            requesting.clear();
            UserMessagingPlatform.showPrivacyOptionsForm(host, ignored -> {
                consentUpdating = false;
                updatePrivacy(UserMessagingPlatform.getConsentInformation(host));
                availability();
            });
        });
    }

    private void availability() { bridge.dispatch("reward_availability"); }
}
