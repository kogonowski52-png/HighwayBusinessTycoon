package pl.krystiandevelopment.highwaytycoon.ads;

import android.app.Activity;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.os.SystemClock;
import android.provider.Settings;
import java.util.HashSet;
import java.util.Set;
import java.util.regex.Pattern;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

public final class HighwayRewarded extends GodotPlugin {
    private static final Pattern TICKET = Pattern.compile("[a-f0-9]{32}");
    private final Ads ads = new Ads(this);
    private final Store store = new Store(this);
    private Bundle metadata;
    private Integer bootCount;
    private volatile boolean suspended;

    public HighwayRewarded(Godot godot) {
        super(godot);
    }

    @Override
    public String getPluginName() {
        return "HighwayRewarded";
    }

    @Override
    public Set<SignalInfo> getPluginSignals() {
        return new HashSet<>(java.util.Arrays.asList(
                new SignalInfo("reward_availability"),
                new SignalInfo("reward_earned", String.class),
                new SignalInfo("reward_closed", String.class),
                new SignalInfo("ad_shown", String.class),
                new SignalInfo("break_shown", String.class),
                new SignalInfo("break_closed", String.class),
                new SignalInfo("billing_catalog", String.class),
                new SignalInfo("billing_purchases", String.class),
                new SignalInfo("billing_state", String.class, Integer.class),
                new SignalInfo("identity_result", String.class)
        ));
    }

    @Override public void onMainPause() { suspended = true; }

    @Override public void onMainResume() {
        suspended = false;
        ads.resume();
    }

    @Override public void onMainDestroy() { store.close(); }

    boolean suspended() { return suspended; }

    Activity activity() {
        Activity host = getActivity();
        return host == null || host.isFinishing() || host.isDestroyed() ? null : host;
    }

    void dispatch(String signal, Object... payload) {
        emitSignal(signal, payload);
    }

    synchronized String config(String key) {
        if (metadata == null) {
            Activity host = activity();
            if (host == null) return "";
            try {
                metadata = host.getPackageManager().getApplicationInfo(
                        host.getPackageName(), PackageManager.GET_META_DATA).metaData;
            } catch (PackageManager.NameNotFoundException ignored) {
                return "";
            }
            if (metadata == null) metadata = new Bundle();
        }
        Object value = metadata.get("highwaytycoon." + key);
        return value == null ? "" : value.toString();
    }

    @UsedByGodot public String clockSample() {
        Activity host = activity();
        if (host == null) return "";
        if (bootCount == null) {
            try {
                bootCount = Settings.Global.getInt(host.getContentResolver(), Settings.Global.BOOT_COUNT, -1);
            } catch (SecurityException ignored) {
                bootCount = -1;
            }
        }
        return bootCount + ":" + SystemClock.elapsedRealtime();
    }

    @UsedByGodot public boolean adsConfigured() { return !config("rewarded_boost").isEmpty(); }
    @UsedByGodot public boolean rewardReady(String slot) { return ads.rewardReady(slot); }
    @UsedByGodot public boolean rewardLoading(String slot) { return ads.rewardLoading(slot); }
    @UsedByGodot public boolean privacyOptionsRequired() { return ads.privacyRequired(); }
    @UsedByGodot public void prepareReward(String slot) { ads.prepareReward(slot); }
    @UsedByGodot public void showPrivacy() { ads.privacy(); }
    @UsedByGodot public boolean showRewarded(String slot, String ticket) {
        return TICKET.matcher(ticket).matches() && !store.checkoutOpen() && ads.showRewarded(slot, ticket);
    }
    @UsedByGodot public boolean breakReady() { return ads.breakReady(); }
    @UsedByGodot public void prepareBreak() { ads.prepareBreak(); }
    @UsedByGodot public boolean showBreak(String ticket) {
        return TICKET.matcher(ticket).matches() && !store.checkoutOpen() && ads.showBreak(ticket);
    }

    @UsedByGodot public boolean diagnosticsEnabled() { return "true".equals(config("diagnostics")); }
    @UsedByGodot public String diagnosticAdState() {
        return diagnosticsEnabled() && adsConfigured() ? ads.initializationStatus() : "unconfigured";
    }
    @UsedByGodot public String diagnosticConsent() {
        return diagnosticsEnabled() && adsConfigured() ? ads.consentStatus() : "unconfigured";
    }
    @UsedByGodot public String diagnosticBilling() {
        return diagnosticsEnabled() && billingConfigured() ? store.diagnosticStatus() : "unconfigured";
    }

    @UsedByGodot public String privacyPolicyUrl() { return config("privacy_url"); }
    @UsedByGodot public String purchaseEndpoint() { return config("backend"); }
    @UsedByGodot public boolean billingConfigured() { return "true".equals(config("billing")); }
    @UsedByGodot public boolean identityConfigured() { return !config("oauth_client").isEmpty(); }

    @UsedByGodot public void startBilling(String ids) {
        if (billingConfigured()) store.connect(ids);
    }
    @UsedByGodot public void restoreBilling() {
        if (billingConfigured()) store.restore();
    }
    @UsedByGodot public boolean launchBilling(String id, String account) {
        return billingConfigured() && !ads.fullscreen() && store.launch(id, account);
    }
    @UsedByGodot public boolean signIn(String nonce) {
        return identityConfigured() && !ads.fullscreen() && store.identify(config("oauth_client"), nonce);
    }
}
