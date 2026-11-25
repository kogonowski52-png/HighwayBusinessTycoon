class_name HbtDistrict
extends Resource
## Site placement shares coordinates with vehicle routes and worker posts.

@export var id: String
@export var name_pl: String
@export var name_en: String
@export var opening_cash: int
@export var arrival_seconds: float
@export var minimum_arrival_seconds: float

func display_name(locale: String) -> String:
	return name_pl if locale == "pl" else name_en
