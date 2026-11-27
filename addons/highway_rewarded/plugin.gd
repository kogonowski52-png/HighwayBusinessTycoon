@tool
extends EditorPlugin

var exporter: EditorExportPlugin

func _enter_tree() -> void:
	exporter = MobileExport.new()
	add_export_plugin(exporter)

func _exit_tree() -> void:
	if exporter != null:
		remove_export_plugin(exporter)

class MobileExport extends EditorExportPlugin:
	const LIBRARY := "res://addons/highway_rewarded/highway-rewarded.aar"
	const TEST_APP := "ca-app-pub-3940256099942544~3347511713"
	const TEST_REWARD := "ca-app-pub-3940256099942544/5224354917"
	const TEST_BREAK := "ca-app-pub-3940256099942544/1033173712"

	func _get_name() -> String:
		return "Highway Monetization Android"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func native_export() -> bool:
		return OS.get_environment("HBT_ANDROID_MODE") in ["test", "closed", "production"] and FileAccess.file_exists(LIBRARY)

	func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray([LIBRARY]) if native_export() else PackedStringArray()

	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		if not native_export():
			return PackedStringArray()
		return PackedStringArray([
			"com.google.android.gms:play-services-ads:25.5.0",
			"com.google.android.ump:user-messaging-platform:4.0.0",
			"com.android.billingclient:billing:9.1.0",
			"androidx.credentials:credentials:1.6.0",
			"androidx.credentials:credentials-play-services-auth:1.6.0",
			"com.google.android.libraries.identity.googleid:googleid:1.2.1",
		])

	func _get_android_manifest_application_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
		if not native_export():
			return ""
		var mode := OS.get_environment("HBT_ANDROID_MODE")
		var test := mode != "production"
		var app := TEST_APP if test else read_identifier("HBT_ADMOB_APP_ID", "~")
		var values := {
			"com.google.android.gms.ads.APPLICATION_ID": app,
			"highwaytycoon.rewarded_boost": TEST_REWARD if test else read_identifier("HBT_REWARDED_BOOST_ID", "/"),
			"highwaytycoon.rewarded_offline": TEST_REWARD if test else read_identifier("HBT_REWARDED_OFFLINE_ID", "/"),
			"highwaytycoon.rewarded_gems": TEST_REWARD if test else read_identifier("HBT_REWARDED_GEMS_ID", "/"),
			"highwaytycoon.rewarded_bonus": TEST_REWARD if test else read_identifier("HBT_REWARDED_BONUS_ID", "/"),
			"highwaytycoon.interstitial": TEST_BREAK if test else read_identifier("HBT_INTERSTITIAL_ID", "/"),
			"highwaytycoon.billing": "false" if mode == "closed" else "true",
			"highwaytycoon.mode": mode,
			"highwaytycoon.diagnostics": "true" if mode == "test" and _debug else "",
		}
		if OS.get_environment("HBT_INTERSTITIALS") == "off":
			values.erase("highwaytycoon.interstitial")
		var url := OS.get_environment("HBT_PLAY_BACKEND").strip_edges()
		var identity := OS.get_environment("HBT_GOOGLE_CLIENT_ID").strip_edges()
		if (mode != "closed"
				and RegEx.create_from_string("^https://[a-zA-Z0-9.-]+(?::[0-9]+)?(/[a-zA-Z0-9/_-]*)?$").search(url) != null
				and RegEx.create_from_string("^[0-9]+-[A-Za-z0-9_-]+\\.apps\\.googleusercontent\\.com$").search(identity) != null):
			values["highwaytycoon.backend"] = url
			values["highwaytycoon.oauth_client"] = identity
		var privacy := OS.get_environment("HBT_PRIVACY_URL").strip_edges()
		if RegEx.create_from_string("^https://[a-zA-Z0-9.-]+(/[a-zA-Z0-9/_.-]*)?$").search(privacy) != null:
			values["highwaytycoon.privacy_url"] = privacy
		var content := ""
		for key in values:
			if not str(values[key]).is_empty():
				content += '<meta-data android:name="%s" android:value="%s" />\n' % [key, str(values[key]).xml_escape(true)]
		return content

	func read_identifier(variable: String, separator: String) -> String:
		var value := OS.get_environment(variable).strip_edges()
		var format := RegEx.create_from_string("^ca-app-pub-[0-9]{16}%s[0-9]{10}$" % separator)
		return value if format.search(value) != null and not value.begins_with("ca-app-pub-3940256099942544") else ""
