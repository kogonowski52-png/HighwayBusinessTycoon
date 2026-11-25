@tool
extends EditorPlugin

var exporter: EditorExportPlugin

func _enter_tree() -> void:
	for key in ["application_id", "rewarded_unit"]:
		var path: String = "highway_rewarded/" + key
		if not ProjectSettings.has_setting(path):
			ProjectSettings.set_setting(path, "")
		ProjectSettings.add_property_info({"name": path, "type": TYPE_STRING})
	exporter = RewardedExport.new()
	add_export_plugin(exporter)

func _exit_tree() -> void:
	if exporter != null:
		remove_export_plugin(exporter)

class RewardedExport extends EditorExportPlugin:
	const LIBRARY := "res://addons/highway_rewarded/highway-rewarded.aar"

	func _get_name() -> String:
		return "HighwayRewarded"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func configured() -> bool:
		var app := RegEx.create_from_string("^ca-app-pub-[0-9]{16}~[0-9]{10}$")
		var reward := RegEx.create_from_string("^ca-app-pub-[0-9]{16}/[0-9]{10}$")
		return FileAccess.file_exists(LIBRARY) and app.search(value("application_id")) != null \
			and reward.search(value("rewarded_unit")) != null

	func value(key: String) -> String:
		return str(ProjectSettings.get_setting("highway_rewarded/" + key, "")).strip_edges()

	func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray([LIBRARY]) if configured() else PackedStringArray()

	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["com.google.android.gms:play-services-ads:24.8.0",
			"com.google.android.ump:user-messaging-platform:3.2.0"]) if configured() else PackedStringArray()

	func _get_android_manifest_application_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
		if not configured():
			return ""
		return '<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="%s" />\n<meta-data android:name="highwaytycoon.rewarded_unit" android:value="%s" />' \
			% [value("application_id"), value("rewarded_unit")]
