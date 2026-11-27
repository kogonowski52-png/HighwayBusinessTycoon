extends RefCounted
## Local awards use the actual wallet, visiting clients, trained crew and commerce ledger.

# Local achievement names, service and metric, threshold, diamond reward, badge family.
const AWARDS := {
	"tropical": [
		["island_keys", "Klucze do wyspy", "Keys to the Island", "rent", "rentals", 5, 4, "customers"],
		["island_roundtrip", "Z powrotem w porcie", "Back at the Marina", "rent", "returns", 4, 5, "calendar"],
		["coral_convoy", "Kolumna skuterów", "Scooter Parade", "scooters", "rentals", 9, 6, "customers"],
		["lagoona_hosts", "Zespół Lagoona", "Lagoona Hosts", "resort", "site_staff", 2, 5, "staff"],
		["reef_order", "Serwis przy rafie", "Reef Service", "restaurant", "site_sales", 24, 6, "customers"],
		["pantry_sales", "Pamiątki z podróży", "Travel Mementos", "market", "shoppers", 20, 5, "gross"],
		["drift_capacity", "Parking na przypływ", "High-Tide Parking", "parking", "site_level", 18, 5, "upgrades"],
		["mist_pro", "Najlepsza piana", "Best in Foam", "wash", "site_training", 4, 7, "training"],
		["palmwater_all", "Cała wyspa", "All of Palmwater", "", "locations", 8, 9, "locations"],
	],
	"route66": [
		["spur_first", "Paliwo na szlak", "Fuel for the Trail", "fuel", "site_sales", 26, 4, "customers"],
		["sunliner_crew", "Zmiana w Sunlinerze", "Sunliner Shift", "restaurant", "site_training", 3, 5, "training"],
		["comet_roads", "Noc pod kometą", "Night Under the Comet", "motel", "site_sales", 27, 6, "calendar"],
		["classic_crew", "Brygada klasyków", "Classics Crew", "workshop", "site_staff", 2, 5, "staff"],
		["axle_counter", "Pełna półka", "Fully Stocked Shelf", "parts", "shoppers", 20, 5, "gross"],
		["brightsteel_turn", "Nowy blask", "Shining Again", "restoration", "site_sales", 12, 7, "customers"],
		["brightsteel_shop", "Druga hala", "The Second Garage", "restoration", "site_level", 30, 7, "upgrades"],
		["classic_reputation", "Znani w Copper Spur", "Known Along Copper Spur", "", "reputation", 125, 6, "reputation"],
		["copper_all", "Cały Copper Spur", "All of Copper Spur", "", "locations", 6, 9, "locations"],
	],
	"harbor": [
		["terminal_in", "Kontenery na nabrzeżu", "Containers on the Quay", "terminal", "inbound", 8, 5, "gross"],
		["terminal_out", "Ładunek w drodze", "Cargo on the Move", "terminal", "outbound", 12, 7, "customers"],
		["dock_two", "Dwa doki", "Two Docks", "transfer", "site_staff", 2, 6, "staff"],
		["cold_in", "Łańcuch chłodniczy", "Cold Chain", "coldstore", "inbound", 9, 7, "gross"],
		["diesel_school", "Certyfikat diesla", "Diesel Certificate", "truck_service", "site_training", 5, 7, "training"],
		["cargo_circle", "Pełna dystrybucja", "Round of Distribution", "distribution", "outbound", 8, 7, "locations"],
		["truck_clean", "Czyste ciągniki", "Clean Tractors", "truck_wash", "site_sales", 21, 6, "customers"],
		["anchor_level", "Długi postój", "Long Haul Stop", "transport", "site_level", 30, 6, "upgrades"],
		["breakwater_all", "Cały Breakwater", "All of Breakwater", "", "locations", 8, 9, "locations"],
	],
	"luxury": [
		["aurum_shift", "Zmiana Aurum", "Aurum Shift", "fuel", "site_training", 5, 4, "training"],
		["onyx_buyer", "Kolekcja klientów", "A Collector's Circle", "dealership", "sold", 6, 7, "gross"],
		["onyx_floor", "Większa ekspozycja", "Showroom Expansion", "dealership", "site_level", 25, 6, "upgrades"],
		["opal_jobs", "Polerowany lakier", "Polished Finish", "detail", "site_sales", 24, 6, "customers"],
		["gilded_crew", "Zespół hotelowy", "Hotel Team", "motel", "site_staff", 2, 5, "staff"],
		["marquee_guests", "Wieczór w Marquee", "An Evening at Marquee", "restaurant", "site_sales", 30, 7, "calendar"],
		["pearl_services", "Bilety na bulwar", "Boulevard Tickets", "vip_park", "site_sales", 18, 6, "customers"],
		["velocity_level", "Wyższa prędkość", "Higher Velocity", "tuning", "site_level", 35, 7, "upgrades"],
		["gilded_all", "Cały Gilded Mile", "All of Gilded Mile", "", "locations", 7, 9, "locations"],
	],
	"japan": [
		["akari_first", "Pierwsze światło", "First Light", "fuel", "site_sales", 24, 5, "customers"],
		["circuit_school", "Licencja torowa", "Track License", "tuning", "site_training", 6, 7, "training"],
		["bowl_guests", "Najlepszy bulion", "Best Broth", "restaurant", "site_sales", 25, 6, "customers"],
		["night_custom", "Zakupy o północy", "Midnight Shopping", "market", "shoppers", 28, 7, "gross"],
		["prism_level", "Przebudowa Prism Jet", "Prism Jet Refit", "wash", "site_level", 30, 6, "upgrades"],
		["ion_all", "Pełne ładowanie", "Charged Up", "charge", "site_sales", 15, 7, "reputation"],
		["ion_crew", "Elektryczna zmiana", "Electric Shift", "charge", "site_staff", 2, 6, "staff"],
		["sakura_deck", "Trzecie stanowisko", "The Third Bay", "parking", "site_level", 43, 7, "upgrades"],
		["akari_all", "Cały Akari Junction", "All of Akari Junction", "", "locations", 7, 9, "locations"],
	],
	"wilderness": [
		["timber_dawn", "Start w Timberline", "A Timberline Start", "fuel", "site_training", 4, 5, "training"],
		["logs_from", "Przyjęcie drewna", "Incoming Timber", "logging", "inbound", 7, 6, "gross"],
		["logs_out", "Drewno w drogę", "Timber Departures", "logging", "outbound", 12, 8, "customers"],
		["boreal_repairs", "Ratunek 4×4", "Four-by-Four Rescue", "workshop", "site_sales", 22, 6, "customers"],
		["ridgeway_crew", "Brygada ciężkiego transportu", "Heavy Haul Team", "haulage", "site_staff", 2, 7, "staff"],
		["trailhead_return", "Powrót ze szlaku", "Return from the Trail", "rent", "returns", 7, 7, "calendar"],
		["lakewatch_stay", "Zimowa noc nad jeziorem", "A Winter Night by the Lake", "motel", "site_sales", 24, 7, "calendar"],
		["frostline_grow", "Nowa hala Frostline", "A New Frostline Bay", "truck_service", "site_level", 30, 7, "upgrades"],
		["timberline_all", "Całe Timberline", "All of Timberline", "", "locations", 7, 10, "locations"],
	],
}

const TASKS := {
	"rent": ["rentals", 4], "scooter": ["returns", 3], "freight": ["inbound", 5],
	"cold": ["outbound", 4], "retail": ["shoppers", 8], "motor": ["sold", 3],
	"repair": ["site_training", 2], "ev": ["site_sales", 8], "wash": ["site_sales", 11],
	"food": ["site_staff", 2], "hotel": ["site_sales", 9], "parking": ["site_level", 18], "fuel": ["site_sales", 8],
}

static func missions(district: String, facilities: Dictionary) -> Dictionary:
	var result := {}
	var position := 0
	for id: String in facilities:
		var service: HbtService = facilities[id]
		var task: Array = TASKS[service.venue_kind]
		var first := "%s_%s_commission" % [district, id]
		var second := "%s_%s_trade" % [district, id]
		var mastery := "%s_%s_hub" % [district, id]
		var rank := mini(10, 2 + position)
		result[first] = {"id": first, "site": id, "rank": rank, "wave": 0, "counter": "site_level", "goal": 1,
			"reward": {"cash": service.base_price * 2}}
		result[second] = {"id": second, "site": id, "rank": rank, "wave": 0, "counter": task[0], "goal": task[1],
			"reward": {"cash": service.base_price * 9, "diamond": 2}}
		result[mastery] = {"id": mastery, "site": id, "rank": rank, "wave": 1, "counter": "site_level",
			"goal": 60, "reward": {"diamond": 5, "event": 2}}
		position += 1
	return result
