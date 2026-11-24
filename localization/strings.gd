extends RefCounted

const COPY := {
	"pl": {
		"location": "LOKALIZACJA 01  /  TRASA 17", "name": "Stacja Północ",
		"road": "RUCH NA TRASIE", "customers": "OBSŁUŻENI", "cash": "KASA STACJI",
		"fuel": "Dystrybutor paliwa", "level": "POZIOM %d / 5", "waiting": "Klient gotowy do obsługi",
		"arriving": "Klient jedzie na stację", "serving": "Tankowanie w toku", "open": "Czekasz na kolejnego klienta",
		"serve": "Rozpocznij tankowanie", "upgrade": "Ulepsz · %d zł", "max": "Maks. poziom",
		"sale": "+%d zł  /  tankowanie zakończone", "money": "%d zł",
		"save_error": "Błąd zapisu postępu", "rate": "%d zł / klient"
	},
	"en": {
		"location": "LOCATION 01  /  ROUTE 17", "name": "Northpoint Station",
		"road": "HIGHWAY TRAFFIC", "customers": "SERVED", "cash": "STATION CASH",
		"fuel": "Fuel dispenser", "level": "LEVEL %d / 5", "waiting": "Customer ready for service",
		"arriving": "Customer approaching the station", "serving": "Refueling in progress", "open": "Waiting for the next customer",
		"serve": "Start refueling", "upgrade": "Upgrade · %d PLN", "max": "Max level",
		"sale": "+%d PLN  /  refueling complete", "money": "%d PLN",
		"save_error": "Progress could not be saved", "rate": "%d PLN / customer"
	}
}

static func phrase(language: String, key: String) -> String:
	return COPY[language][key]
