extends RefCounted
## Money fields are in full złoty. Capacity is in pallets or equivalent loads.

const TYPES := {
	"van": {"name": ["Dostawczy Parcel", "Parcel van"], "model": "parcel", "price": 740, "capacity": 4, "speed": 1.18, "running": 18, "cargo": ["goods", "parts", "vip"]},
	"truck": {"name": ["Ciężarówka Boxmaster", "Boxmaster truck"], "model": "container", "price": 4750, "capacity": 10, "speed": 1.0, "running": 46, "cargo": ["goods", "parts", "vip", "materials"]},
	"tank": {"name": ["Cysterna Solara", "Solara tanker"], "model": "atlas", "price": 7200, "capacity": 14, "speed": .88, "running": 62, "cargo": ["fuel"]},
	"tractor": {"name": ["Ciągnik Atlas", "Atlas tractor"], "model": "atlas", "price": 9200, "capacity": 0, "speed": .93, "running": 66, "cargo": []},
}

const TRAILERS := {
	"freight": {"name": ["Naczepa kurtynowa", "Curtain-side trailer"], "model": "cargo", "price": 1900, "capacity": 17, "cargo": ["goods", "parts", "vip"]},
	"cold": {"name": ["Naczepa chłodnicza", "Refrigerated trailer"], "model": "cooler", "price": 2900, "capacity": 16, "cargo": ["food", "vip"]},
	"deck": {"name": ["Platforma stalowa", "Steel deck trailer"], "model": "container", "price": 3100, "capacity": 21, "cargo": ["containers", "materials"]},
	"logging": {"name": ["Naczepa do drewna", "Logging trailer"], "model": "timber", "price": 3700, "capacity": 24, "cargo": ["timber", "materials"]},
	"autos": {"name": ["Laweta piętrowa", "Double-deck transporter"], "model": "petrel", "price": 4200, "capacity": 9, "cargo": ["cars", "vip"]},
}

const DRIVER_NAMES := ["Maja Lis", "Ivo Campos", "Lena Fox", "Tom Okada", "Samir Haddad", "Ewa Brzeg",
	"Ian Shaw", "Nadia Wells", "Elli Berg", "Noah Reed", "Kai Endo", "Mina Winters"]
const MAX_TRUCKS := 16
const MAX_DRIVER_RANK := 6
const DRIVER_PRICE := 240
const DEPOT_LEVEL := 4
const MIN_CONDITION := 45
