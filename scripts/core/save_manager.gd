extends RefCounted

var path := "user://roadside.cfg"

func read_progress() -> ConfigFile:
	var file := ConfigFile.new()
	var result := file.load(path)
	if result != OK:
		file = ConfigFile.new()
		file.load(path + ".backup")
	return file

func write_progress(file: ConfigFile) -> Error:
	var result := file.save(path + ".tmp")
	if result != OK:
		return result
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		var backup_result := DirAccess.copy_absolute(absolute, absolute + ".backup")
		if backup_result != OK:
			return backup_result
	return DirAccess.rename_absolute(absolute + ".tmp", absolute)
