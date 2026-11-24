extends SceneTree

var checks := 0
var failures := 0

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)

func result(label: String) -> void:
	print("%s: %d/%d passed" % [label, checks - failures, checks])
	quit(0 if failures == 0 else 1)

func clean_save(base: String) -> void:
	for suffix in ["", ".backup", ".tmp", ".backup.tmp"]:
		if FileAccess.file_exists(base + suffix):
			DirAccess.remove_absolute(base + suffix)
