extends "res://tests/run_checks.gd"

const Strings = preload("res://localization/strings.gd")
const Atlas = preload("res://data/world/atlas.gd")
const EXTENSIONS := ["gd", "tscn", "tres", "glb", "png", "jpg", "svg", "gdshader", "ttf", "ogg", "wav"]

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var counts := {}
	var ui_keys := {}
	var key_pattern := RegEx.create_from_string('\\bt\\("([a-zA-Z0-9_]+)"(?:\\)|\\s*%)')
	for tree in ["assets", "scenes", "scripts", "data", "localization", "addons/highway_rewarded"]:
		for path in walk("res://" + tree):
			var extension := path.get_extension()
			if extension not in EXTENSIONS:
				continue
			var resource := ResourceLoader.load(path)
			expect(resource != null, "release resource imports · " + path)
			if resource is PackedScene:
				expect(resource.can_instantiate(), "scene can instantiate · " + path)
			elif resource is Script:
				expect(resource.can_instantiate(), "script can instantiate · " + path)
				for match_key in key_pattern.search_all(FileAccess.get_file_as_string(path)):
					ui_keys[match_key.get_string(1)] = true
			counts[extension] = int(counts.get(extension, 0)) + 1
	print("Inventory ", JSON.stringify(counts))
	localization(ui_keys)
	var services := 0
	var missions := 0
	for region: String in Atlas.DESTINATIONS:
		var estate := HbtEconomy.new(region)
		services += estate.facilities.size()
		missions += estate.missions.size()
		for id: String in estate.facilities:
			var service: HbtService = estate.facilities[id]
			expect(not service.name_en.strip_edges().is_empty() and not service.name_pl.strip_edges().is_empty(),
				"localized service · %s/%s" % [region, id])
		print("%s · %d services · %d missions" % [region, estate.facilities.size(), estate.missions.size()])
	expect(Atlas.DESTINATIONS.size() == 12 and services == 84 and missions == 719, "twelve playable districts, 84 services and 719 chapter missions")
	result("Release resource and locale audit")

func walk(directory: String) -> PackedStringArray:
	var paths := PackedStringArray()
	for file in DirAccess.get_files_at(directory):
		paths.append(directory.path_join(file))
	for folder in DirAccess.get_directories_at(directory):
		paths.append_array(walk(directory.path_join(folder)))
	return paths

func localization(ui_keys: Dictionary) -> void:
	var keys := {}
	for language: String in ["en", "pl"]:
		for key: String in Strings.COPY[language]:
			keys[key] = true
	for table: Dictionary in [Strings.ADVANCED.COPY, Strings.MONETIZATION.COPY, Strings.EXPEDITION.COPY, Strings.PRESENTATION, Strings.IDLE]:
		for key: String in table:
			keys[key] = true
	var format := RegEx.create_from_string("%[-0-9.]*[dfs]")
	for key: String in keys:
		var polish := localized(key, "pl")
		var english := localized(key, "en")
		expect(not polish.strip_edges().is_empty() and not english.strip_edges().is_empty(),
			"both localized surfaces present · " + key)
		expect(format.search_all(polish).size() == format.search_all(english).size(), "same format arity · " + key)
	for key: String in ui_keys:
		expect(keys.has(key), "literal UI key exists · " + key)
	print("Locale inventory · %d bilingual keys · %d literal UI lookups" % [keys.size(), ui_keys.size()])

func localized(key: String, language: String) -> String:
	for table: Dictionary in [Strings.ADVANCED.COPY, Strings.MONETIZATION.COPY, Strings.EXPEDITION.COPY, Strings.PRESENTATION, Strings.IDLE]:
		if table.has(key):
			return table[key][int(language == "en")]
	return Strings.COPY[language].get(key, "")
