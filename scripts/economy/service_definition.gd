class_name HbtService
extends Resource

@export var id: String
@export var name_pl: String
@export var name_en: String
@export var base_price: int
@export var first_upgrade: int
@export var upgrade_growth: int
@export var price_growth: int
@export var seconds: float
@export var minimum_seconds: float
@export var unlock_cost: int
@export var reputation_gate: int
@export var prerequisite: String
@export var prerequisite_level: int
@export var wage: int
@export var capacity_levels: Array[int] = [1]
@export var vehicle_kind := "car"
@export var role := "attendant"
@export var task := "service"
@export var venue_kind := ""
