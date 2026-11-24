package pl.krystiandevelopment.highwaytycoon.ads;

import android.app.Activity;
import android.content.pm.PackageManager;
import android.os.Bundle;

import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.rewarded.RewardedAd;
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback;
import com.google.android.ump.ConsentInformation;
import com.google.android.ump.ConsentRequestParameters;
import com.google.android.ump.UserMessagingPlatform;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.atomic.AtomicBoolean;

public final class HighwayRewarded extends GodotPlugin {
    private final AtomicBoolean loading = new AtomicBoolean(false);
    private final AtomicBoolean ready = new AtomicBoolean(false);
    private volatile boolean privacyRequired;
    // The ad instance and the consent lifecycle belong to the Android UI thread.
    private RewardedAd ad;

    public HighwayRewarded(Godot godot) {
        super(godot);
    }

    @Override
    public String getPluginName() {
        return "HighwayRewarded";
    }

    @Override
    public Set<SignalInfo> getPluginSignals() {
        return new HashSet<>(Arrays.asList(
                new SignalInfo("reward_availability"),
                new SignalInfo("reward_earned", String.class),
                new SignalInfo("reward_closed", String.class)
        ));
    }

    @UsedByGodot
    public boolean rewardReady() {
        return ready.get();
    }

    @UsedByGodot
    public boolean rewardLoading() {
        return loading.get();
    }

    @UsedByGodot
    public boolean privacyOptionsRequired() {
        return privacyRequired;
    }

    @UsedByGodot
    public void prepare() {
        Activity activity = getActivity();
        if (activity == null || ready.get() || !loading.compareAndSet(false, true)) {
            return;
        }
        activity.runOnUiThread(() -> requestConsent(activity));
    }

    private void requestConsent(Activity activity) {
        String adUnit = configuration(activity);
        if (adUnit.isEmpty()) {
            finishLoad(false);
            return;
        }
        ConsentInformation consent = UserMessagingPlatform.getConsentInformation(activity);
        ConsentRequestParameters parameters = new ConsentRequestParameters.Builder().build();
        consent.requestConsentInfoUpdate(
                activity, parameters,
                () -> UserMessagingPlatform.loadAndShowConsentFormIfRequired(activity, formError -> {
                    updatePrivacy(consent);
                    loadIfPermitted(activity, consent, adUnit);
                }),
                error -> {
                    updatePrivacy(consent);
                    loadIfPermitted(activity, consent, adUnit);
                }
        );
    }

    private void loadIfPermitted(Activity activity, ConsentInformation consent, String adUnit) {
        if (!consent.canRequestAds() || activity.isFinishing()) {
            finishLoad(false);
            return;
        }
        MobileAds.initialize(activity, initialized -> activity.runOnUiThread(() ->
                RewardedAd.load(activity, adUnit, new AdRequest.Builder().build(),
                        new RewardedAdLoadCallback() {
                            @Override
                            public void onAdLoaded(RewardedAd loadedAd) {
                                ad = loadedAd;
                                finishLoad(true);
                            }

                            @Override
                            public void onAdFailedToLoad(LoadAdError error) {
                                ad = null;
                                finishLoad(false);
                            }
                        })));
    }

    private String configuration(Activity activity) {
        try {
            Bundle data = activity.getPackageManager().getApplicationInfo(
                    activity.getPackageName(), PackageManager.GET_META_DATA).metaData;
            return data == null ? "" : data.getString("highwaytycoon.rewarded_unit", "");
        } catch (PackageManager.NameNotFoundException error) {
            return "";
        }
    }

    private void finishLoad(boolean success) {
        ready.set(success);
        loading.set(false);
        emitSignal("reward_availability");
    }

    private void updatePrivacy(ConsentInformation consent) {
        privacyRequired = consent.getPrivacyOptionsRequirementStatus()
                == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED;
    }

    @UsedByGodot
    public boolean showOffline(String requestId) {
        Activity activity = getActivity();
        if (activity == null || requestId.isEmpty() || !ready.compareAndSet(true, false)) {
            return false;
        }
        activity.runOnUiThread(() -> {
            RewardedAd shown = ad;
            ad = null;
            if (shown == null || activity.isFinishing()) {
                emitSignal("reward_closed", requestId);
                return;
            }
            shown.setFullScreenContentCallback(new FullScreenContentCallback() {
                @Override
                public void onAdDismissedFullScreenContent() {
                    emitSignal("reward_closed", requestId);
                }

                @Override
                public void onAdFailedToShowFullScreenContent(AdError error) {
                    emitSignal("reward_closed", requestId);
                }
            });
            shown.show(activity, reward -> emitSignal("reward_earned", requestId));
        });
        return true;
    }

    @UsedByGodot
    public void showPrivacy() {
        Activity activity = getActivity();
        if (activity == null || !privacyRequired || loading.get()) {
            return;
        }
        ready.set(false);
        activity.runOnUiThread(() -> {
            ad = null;
            UserMessagingPlatform.showPrivacyOptionsForm(activity, error -> {
                updatePrivacy(UserMessagingPlatform.getConsentInformation(activity));
                emitSignal("reward_availability");
            });
        });
    }
}
