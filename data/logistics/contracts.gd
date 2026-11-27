extends RefCounted

const GOODS := {
	"fuel": ["Paliwo", "Fuel"], "goods": ["Towary", "Goods"], "food": ["Żywność", "Food"],
	"parts": ["Części", "Parts"], "materials": ["Materiały", "Materials"],
	"containers": ["Kontenery", "Containers"], "vip": ["Dostawa VIP", "VIP delivery"],
	"cars": ["Samochody", "Cars"], "timber": ["Drewno", "Timber"],
}
const ALLOWED := {
	"fuel": "tank", "goods": "van / truck / freight", "food": "cold", "parts": "van / truck / freight",
	"materials": "truck / deck / logging", "containers": "deck", "vip": "van / truck / cold / autos / freight",
	"cars": "autos", "timber": "logging",
}

# Destination, cargo, quantity, route difficulty, customer. Each contract is repeatable with a rest period.
const ROUTES := {
	"north": [["north","parts",2,0,"Route 17 Service"], ["valley","goods",4,0,"Greenbank"],
		["desert","fuel",10,1,"Copper Mile Reserve"], ["metro","materials",11,2,"Meridian Works"], ["ocean","vip",4,2,"Coral Key Club"]],
	"desert": [["desert","goods",3,0,"Dust & Bean"], ["north","fuel",12,1,"Northpoint Reserve"],
		["route66","parts",6,1,"Axle Supply"], ["alpine","materials",17,2,"Snowline Works"], ["harbor","containers",15,3,"Tidegate"]],
	"valley": [["valley","goods",2,0,"Greenbank Market"], ["alpine","food",7,1,"Ember Hearth"],
		["tropical","food",14,3,"Reef Deck Kitchen"], ["metro","parts",9,2,"Pulse Service"], ["north","vip",5,1,"Northpoint Welcome"]],
	"alpine": [["alpine","parts",3,0,"Summit Repair"], ["valley","food",6,1,"Orchard Table"],
		["wilderness","materials",13,2,"Timberline Roads"], ["desert","fuel",13,3,"Snowline Reserve"], ["luxury","vip",8,3,"Gilded Garden"]],
	"ocean": [["ocean","vip",3,0,"Blue Current Marina"], ["tropical","food",8,1,"Beach Clubs"],
		["north","goods",8,2,"Coral Key Merchants"], ["japan","cars",6,3,"Akari Expo"], ["harbor","containers",12,2,"Saltwater Export"]],
	"metro": [["metro","goods",4,0,"Crossline Mall"], ["harbor","containers",19,2,"Meridian Freight"],
		["luxury","cars",7,2,"Apex Motors"], ["japan","parts",14,3,"Precision Junction"], ["wilderness","materials",21,3,"Ridgeway Works"]],
	"tropical": [["tropical","goods",3,0,"Island Pantry"], ["ocean","food",12,1,"Pearl Bay Catering"],
		["route66","vip",6,2,"Palmwater Holidays"], ["harbor","containers",11,2,"Dock Island Express"], ["luxury","cars",8,3,"Lagoon Rentals"]],
	"route66": [["route66","parts",4,0,"Lowline Garage"], ["desert","fuel",11,1,"Copper Spur Reserve"],
		["valley","goods",7,1,"Sunliner Market"], ["luxury","cars",8,2,"Brightsteel Classics"], ["wilderness","materials",16,3,"Comet Court Works"]],
	"harbor": [["harbor","goods",4,0,"Cargo Circle"], ["metro","containers",16,1,"Swing Dock"],
		["tropical","food",12,2,"Northcold Express"], ["japan","containers",21,3,"Akari Port Rail"], ["wilderness","timber",20,3,"Logbridge Exports"]],
	"luxury": [["luxury","vip",4,0,"Marquee Concierge"], ["ocean","food",9,1,"Pearl Court Catering"],
		["japan","cars",9,3,"Onyx Atelier"], ["route66","parts",10,2,"Velocity Classics"], ["desert","fuel",14,3,"Aurum Reserve"]],
	"japan": [["japan","parts",4,0,"Akari Circuit"], ["harbor","containers",18,2,"Ion Components"],
		["metro","parts",8,1,"Night Pantry Express"], ["luxury","cars",8,2,"Sakura Collector"], ["tropical","food",15,3,"Lantern Bowl"]],
	"wilderness": [["wilderness","parts",3,0,"Frostline Service"], ["alpine","fuel",12,1,"Lakewatch Reserve"],
		["harbor","timber",22,3,"Timberline Sawmill"], ["metro","materials",19,2,"Ridgeway Build"], ["valley","goods",8,2,"Northern Traders"]],
}

static func contract(id: String) -> Dictionary:
	var region := id.get_slice("/", 0)
	var index := id.get_slice("/", 1)
	if not ROUTES.has(region) or not index.is_valid_int() or int(index) not in range(ROUTES[region].size()):
		return {}
	var row: Array = ROUTES[region][int(index)]
	return {"id": id, "from": region, "to": row[0], "cargo": row[1], "load": row[2], "difficulty": row[3],
		"name": row[4], "seconds": 40 + int(row[3]) * 50 + int(row[2]) * 3 + (22 if row[0] != region else 0)}

static func ids(region: String) -> Array[String]:
	var answer: Array[String] = []
	for index in ROUTES.get(region, []).size():
		answer.append("%s/%d" % [region, index])
	return answer
