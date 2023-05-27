extends Node

signal eggs_changed(count: int)
signal chickens_changed(count: int)
signal supply_changed(count: int)

enum ChickenType {BROWN, WHITE}

var skip_intro := false
var golden_egg_value := 5
var golden_egg_chickens_threshold := 50
var starting_eggs := 30
var golden_feed := false
var unlocked_area := 0
var laying_period := 8.0
var spawn_count := 1
var upgrade_unlocked : Array[int] = []

var supply: int:
	get:
		return int(((owned_cells - 15) * 0.5 + 15) * supply_per_cell)
	set(_v):
		assert(false)

var supply_per_cell := 1.0:
	get:
		return supply_per_cell
	set(c):
		supply_per_cell = c
		supply_changed.emit(supply)
var owned_cells := 0.0:
	get:
		return owned_cells
	set(c):
		owned_cells = c
		supply_changed.emit(supply)

var eggs := 0:
	get:
		return eggs
	set(c):
		eggs = c
		eggs_changed.emit(eggs)

var chickens := 0:
	get:
		return chickens
	set(c):
		chickens = c
		chickens_changed.emit(chickens)

