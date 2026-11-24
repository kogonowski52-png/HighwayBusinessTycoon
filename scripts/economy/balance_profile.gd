class_name HbtBalance
extends Resource

@export var opening_cash := 120
@export var max_level := 100
@export var cost_growth_checkpoints: Array[Vector2i]
@export var offline_cap_seconds := 28_800
@export var offline_efficiency := 58
@export var clock_tolerance_seconds := 120
@export var checkpoint_seconds := 10.0
@export var boost_cost := 4
@export var boost_seconds := 180
@export var boost_multiplier := 12_500
@export var arrival_seconds := 3.7
@export var minimum_arrival_seconds := 1.75
@export var max_active_managers := 3
@export var services: Array[HbtService]
