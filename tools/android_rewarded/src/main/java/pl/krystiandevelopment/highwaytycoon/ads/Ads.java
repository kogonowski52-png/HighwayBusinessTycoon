package pl.krystiandevelopment.highwaytycoon.ads;

import android.app.Activity;
import android.os.Handler;
import android.os.Looper;
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

import java.util.LinkedHashMap;
import java.util.Map;

final class Ads {
    private static final String BREAK = "interstitial";
    private static final long EXPIRATION = 50 * 60_000L;
    private static final long LOAD_TIMEOUT = 25_000L;
    private static final long[] RETRY = {3_000, 8_000, 20_000, 60_000, 120_000};
    private final HighwayRewarded bridge;
    private final Handler main = new Handler(Looper.getMainLooper());
    private final Runnable scheduled = this::pump;
    private final Map<String, Placement> placements = new LinkedHashMap<>();
    private volatile Launch launch;
    private volatile boolean running;
    private volatile boolean consentUpdating;
    private volatile boolean consentAllowed;
    private volatile boolean initializing;
    private volatile boolean initialized;
    private volatile boolean privacyRequired;
    private volatile String consentLabel = "idle";
    private volatile String consentError = "";
    // Request bookkeeping is owned by the UI thread.
    private volatile boolean consentChecked;
    private long consentRetryAt;

    private static final class Loaded {
        final Object ad;
        final long expires = SystemClock.elapsedRealtime() + EXPIRATION;
        Loaded(Object ad) { this.ad = ad; }
    }

    private static final class Placement {
        final String name;
        final String config;
        volatile Loaded loaded;
        volatile String phase = "unavailable";
        volatile String error = "";
        volatile long duration = -1;
        long startedAt;
        long retryAt;
        int failures;
        int requestId;
        boolean requesting;
        boolean previouslyLoaded;

        Placement(String name) {
            this.name = name;
            config = BREAK.equals(name) ? name : "rewarded_" + name;
        }
    }

    private static final class Launch {
        final Placement placement;
        final Loaded loaded;
        final String ticket;
        boolean started;
        boolean awarded;
        boolean shown;

        Launch(Placement placement, Loaded loaded, String ticket) {
            this.placement = placement;
            this.loaded = loaded;
            this.ticket = ticket;
        }
    }

    Ads(HighwayRewarded bridge) {
        this.bridge = bridge;
        for (String name : new String[]{"boost", "offline", "bonus", BREAK}) {
            placements.put(name, new Placement(name));
        }
    }

    boolean fullscreen() { return launch != null; }
    boolean privacyRequired() { return privacyRequired; }

    String initializationStatus() {
        if (initialized) return "ready";
        if (initializing || consentUpdating || running && !consentChecked) return "initializing";
        return running ? "unavailable" : "idle";
    }

    String consentStatus() { return consentUpdating ? "loading" : consentLabel; }
    String consentProblem() { return consentError; }

    boolean rewardReady(String slot) {
        return !BREAK.equals(slot) && "ready".equals(state(slot));
    }
    boolean rewardLoading(String slot) {
        String state = state(slot);
        return "loading".equals(state) || "reloading".equals(state) || "initializing".equals(state);
    }
    boolean breakReady() { return "ready".equals(state(BREAK)); }

    String state(String name) {
        Placement slot = placements.get(name);
        if (slot == null || bridge.config(slot.config).isEmpty() || !running) return "unavailable";
        Launch active = launch;
        if (active != null && active.placement == slot) return "showing";
        if (consentUpdating || !consentChecked || initializing) return "initializing";
        if (!consentAllowed || bridge.suspended()) return "unavailable";
        Loaded item = slot.loaded;
        if (item != null && SystemClock.elapsedRealtime() < item.expires) return "ready";
        return "ready".equals(slot.phase) ? "reloading" : slot.phase;
    }

    String diagnostic(String name) {
        Placement slot = placements.get(name);
        if (slot == null || bridge.config(slot.config).isEmpty()) return "unconfigured|-1|";
        return state(name) + "|" + slot.duration + "|" + slot.error;
    }

    void start() {
        running = true;
        main.post(scheduled);
    }

    void resume() {
        if (running) main.post(scheduled);
    }

    void stop() {
        running = false;
        main.removeCallbacks(scheduled);
    }

    void prepareReward(String slot) {
        Placement placement = placements.get(slot);
        if (placement == null || BREAK.equals(slot)) return;
        running = true;
        main.post(() -> {
            // A fresh user request can retry sooner after an offline period.
            if (!placement.requesting && SystemClock.elapsedRealtime() - placement.startedAt >= RETRY[0]) {
                placement.retryAt = 0;
            }
            pump();
        });
    }

    void prepareBreak() { start(); }

    private void pump() {
        main.removeCallbacks(scheduled);
        Activity host = bridge.activity();
        if (!running || host == null || bridge.suspended() || fullscreen() || consentUpdating) return;
        long now = SystemClock.elapsedRealtime();
        if (!consentChecked || !consentAllowed && consentRetryAt > 0) {
            if (now < consentRetryAt) {
                schedule(consentRetryAt - now);
                return;
            }
            requestConsent(host);
            return;
        }
        if (!consentAllowed || initializing) return;
        if (!initialized) {
            initializing = true;
            availability();
            MobileAds.initialize(host.getApplicationContext(), unused -> main.post(() -> {
                initialized = true;
                initializing = false;
                availability();
                pump();
            }));
            return;
        }
        long wakeAt = Long.MAX_VALUE;
        for (Placement slot : placements.values()) {
            if (bridge.config(slot.config).isEmpty()) continue;
            if (slot.requesting) {
                long deadline = slot.startedAt + LOAD_TIMEOUT;
                if (now >= deadline) loaded(slot, null, "load:timeout", slot.requestId);
                else wakeAt = Math.min(wakeAt, deadline);
                continue;
            }
            Loaded item = slot.loaded;
            if (item != null && now < item.expires) {
                wakeAt = Math.min(wakeAt, item.expires);
            } else if (now >= slot.retryAt) {
                load(host, slot);
                wakeAt = Math.min(wakeAt, now + LOAD_TIMEOUT);
            } else {
                wakeAt = Math.min(wakeAt, slot.retryAt);
            }
        }
        if (wakeAt < Long.MAX_VALUE) schedule(wakeAt - now);
    }

    private void schedule(long delay) {
        main.postDelayed(scheduled, Math.max(1, delay));
    }

    private void requestConsent(Activity host) {
        consentUpdating = true;
        availability();
        ConsentInformation consent = UserMessagingPlatform.getConsentInformation(host);
        var parameters = new ConsentRequestParameters.Builder().build();
        consent.requestConsentInfoUpdate(host, parameters, () -> {
            if (bridge.activity() == null) return;
            if (bridge.suspended()) {
                consentUpdating = false;
                return;
            }
            UserMessagingPlatform.loadAndShowConsentFormIfRequired(host,
                problem -> afterConsent(consent, problem == null ? "" : Integer.toString(problem.getErrorCode())));
        }, failure -> afterConsent(consent, Integer.toString(failure.getErrorCode())));
    }

    private void afterConsent(ConsentInformation consent, String error) {
        consentError = error;
        updatePrivacy(consent);
        consentChecked = true;
        consentRetryAt = !consentAllowed && !error.isEmpty() ? SystemClock.elapsedRealtime() + 30_000 : 0;
        consentUpdating = false;
        availability();
        pump();
    }

    private void updatePrivacy(ConsentInformation consent) {
        consentAllowed = consent.canRequestAds();
        privacyRequired = consent.getPrivacyOptionsRequirementStatus()
            == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED;
        consentLabel = !consentAllowed ? "blocked" : privacyRequired ? "required"
            : consent.getConsentStatus() == ConsentInformation.ConsentStatus.NOT_REQUIRED ? "not_required" : "allowed";
    }

    private void load(Activity host, Placement slot) {
        synchronized (this) {
            if (fullscreen() || bridge.suspended()) return;
            slot.loaded = null;
            slot.requesting = true;
        }
        slot.phase = slot.previouslyLoaded || slot.failures > 0 ? "reloading" : "loading";
        slot.startedAt = SystemClock.elapsedRealtime();
        availability();
        int requestId = ++slot.requestId;
        String id = bridge.config(slot.config);
        AdRequest request = new AdRequest.Builder().build();
        try {
            if (BREAK.equals(slot.name)) {
                InterstitialAd.load(host, id, request, new InterstitialAdLoadCallback() {
                    @Override public void onAdLoaded(InterstitialAd ad) { loaded(slot, ad, "", requestId); }
                    @Override public void onAdFailedToLoad(LoadAdError problem) { loaded(slot, null, "load:" + problem.getCode(), requestId); }
                });
            } else {
                RewardedAd.load(host, id, request, new RewardedAdLoadCallback() {
                    @Override public void onAdLoaded(RewardedAd ad) { loaded(slot, ad, "", requestId); }
                    @Override public void onAdFailedToLoad(LoadAdError problem) { loaded(slot, null, "load:" + problem.getCode(), requestId); }
                });
            }
        } catch (RuntimeException ignored) {
            loaded(slot, null, "load:exception", requestId);
        }
    }

    private void loaded(Placement slot, Object ad, String error, int requestId) {
        if (!running || !slot.requesting || slot.requestId != requestId) return;
        slot.requesting = false;
        slot.duration = SystemClock.elapsedRealtime() - slot.startedAt;
        if (ad != null) {
            slot.previouslyLoaded = true;
            slot.failures = 0;
            slot.retryAt = 0;
            slot.loaded = new Loaded(ad);
            slot.phase = "ready";
        } else {
            slot.error = error;
            slot.phase = "unavailable";
            slot.retryAt = SystemClock.elapsedRealtime() + RETRY[Math.min(slot.failures, RETRY.length - 1)];
            slot.failures = Math.min(slot.failures + 1, RETRY.length);
        }
        availability();
        main.post(scheduled);
    }

    boolean showRewarded(String slot, String ticket) {
        return !BREAK.equals(slot) && show(slot, ticket);
    }

    boolean showBreak(String ticket) { return show(BREAK, ticket); }

    private synchronized boolean show(String name, String ticket) {
        if (fullscreen() || !"ready".equals(state(name)) || bridge.activity() == null || bridge.checkoutOpen()) return false;
        Placement slot = placements.get(name);
        Loaded item = slot.loaded;
        if (item == null || item.expires <= SystemClock.elapsedRealtime()) return false;
        Launch selected = new Launch(slot, item, ticket);
        launch = selected;
        slot.loaded = null;
        main.post(() -> display(selected));
        return true;
    }

    synchronized boolean cancelRewarded(String ticket) {
        Launch selected = launch;
        if (selected == null || selected.started || !selected.ticket.equals(ticket)
                || BREAK.equals(selected.placement.name)) return false;
        selected.placement.loaded = selected.loaded;
        launch = null;
        main.post(scheduled);
        return true;
    }

    private void display(Launch selected) {
        synchronized (this) {
            if (launch != selected) return;
            selected.started = true;
        }
        Activity host = bridge.activity();
        if (host == null || bridge.suspended() || !consentAllowed || bridge.checkoutOpen()
                || selected.loaded.expires <= SystemClock.elapsedRealtime()) {
            close(selected, "show:activity");
            return;
        }
        boolean interstitial = BREAK.equals(selected.placement.name);
        var callback = new FullScreenContentCallback() {
            @Override public void onAdShowedFullScreenContent() {
                if (launch != selected || selected.shown) return;
                selected.shown = true;
                bridge.dispatch(interstitial ? "break_shown" : "ad_shown",
                    interstitial ? selected.ticket : selected.placement.name);
            }
            @Override public void onAdDismissedFullScreenContent() { close(selected, ""); }
            @Override public void onAdFailedToShowFullScreenContent(AdError failure) {
                close(selected, "show:" + failure.getCode());
            }
        };
        try {
            if (interstitial) {
                InterstitialAd ad = (InterstitialAd) selected.loaded.ad;
                ad.setFullScreenContentCallback(callback);
                ad.show(host);
            } else {
                RewardedAd ad = (RewardedAd) selected.loaded.ad;
                ad.setFullScreenContentCallback(callback);
                ad.show(host, item -> {
                    if (launch != selected || selected.awarded) return;
                    selected.awarded = true;
                    bridge.dispatch("reward_earned", selected.ticket);
                });
            }
        } catch (RuntimeException ignored) {
            close(selected, "show:exception");
        }
    }

    private synchronized void close(Launch selected, String error) {
        if (launch != selected) return;
        var slot = selected.placement;
        if (!error.isEmpty()) slot.error = error;
        slot.phase = "reloading";
        launch = null;
        if (!running) return;
        if (!BREAK.equals(slot.name) && !error.isEmpty()) bridge.dispatch("reward_show_failed", selected.ticket);
        bridge.dispatch(BREAK.equals(slot.name) ? "break_closed" : "reward_closed", selected.ticket);
        availability();
        main.post(scheduled);
    }

    void privacy() {
        Activity host = bridge.activity();
        if (host == null || !privacyRequired || fullscreen()) return;
        main.post(() -> {
            synchronized (this) {
                if (consentUpdating || fullscreen() || bridge.suspended()) return;
                consentUpdating = true;
                for (Placement slot : placements.values()) {
                    slot.loaded = null;
                    slot.requesting = false;
                    slot.phase = "unavailable";
                    slot.retryAt = 0;
                }
            }
            availability();
            UserMessagingPlatform.showPrivacyOptionsForm(host, problem -> afterConsent(
                UserMessagingPlatform.getConsentInformation(host),
                problem == null ? "" : Integer.toString(problem.getErrorCode())));
        });
    }

    private void availability() { if (running) bridge.dispatch("reward_availability"); }
}
