class_name HUD
extends Control

signal spawn_chicken(type: Global.ChickenType)
signal feed(golden_feed: bool)
signal unlock_area(index: int)
signal unlock_cup()
signal unlock_flowers()
signal unlock_water_cups()

const brown_chicken_icon := preload("res://assets/images/chicken-brown-icon.atlastex")
const white_chicken_icon := preload("res://assets/images/chicken-white-icon.atlastex")
const golden_nuggets_icon := preload("res://assets/images/golden-nuggets.atlastex")
const expand_icon := preload("res://assets/images/expand.atlastex")
const flower_icon := preload("res://assets/images/red-flower.atlastex")
const fence_icon := preload("res://assets/images/fence.atlastex")
const water_cup_icon := preload("res://assets/images/water-cup.atlastex")

@onready var eggs_label := $PanelContainer/MarginContainer/HBoxContainer/EggsLabel as Label
@onready var chickens_label := $PanelContainer/MarginContainer/HBoxContainer/ChickenLabel as Label
@onready var purchase_menu := $PanelContainer/MarginContainer/HBoxContainer/UpgradeMenu as MenuButton
@onready var feed_button := $PanelContainer/MarginContainer/HBoxContainer/FeedButton as Button
@onready var feed_timer := $PanelContainer/MarginContainer/HBoxContainer/FeedButton/Timer as Timer
@onready var menu := purchase_menu.get_popup()
@onready var victory := $VictoryContainer as Control
@onready var victory_button := $VictoryContainer/MarginContainer/VBoxContainer/Button as Button

enum OptionIndex {
	BROWN_CHICKEN=1000,
	WHITE_CHICKEN=1001,
	AREA1=1002,
	AREA2=1003,
	AREA3=1004,
	AREA4=1005,
	LAY_SPEED=1006,
	SUPPLY=1007,
	GOLDEN_FEED=1008,
	CUP=1009,
	FEED=1010,
}
const AllOptionIndex = [
	#OptionIndex.BROWN_CHICKEN,
	#OptionIndex.WHITE_CHICKEN,
	#OptionIndex.AREA1, OptionIndex.AREA2, OptionIndex.AREA3, OptionIndex.AREA4,
	#OptionIndex.LAY_SPEED, OptionIndex.SUPPLY, OptionIndex.GOLDEN_FEED,
	OptionIndex.CUP
]
var upgrade_desc_text := {
	OptionIndex.LAY_SPEED: "Cute Flowers (laying rate +30%)",
	OptionIndex.SUPPLY: "Fresh Water (supply +50%)",
	OptionIndex.GOLDEN_FEED: "Golden Nuggets Feeding (???)"
}
var upgrade_cond_text := {
	OptionIndex.LAY_SPEED: "Cute Flowers (laying rate +30%)",
	OptionIndex.SUPPLY: "-- Buy all areas to unlock --",
	OptionIndex.GOLDEN_FEED: "-- Own 50 chickens to unlock --"
}
var costs := {
	OptionIndex.BROWN_CHICKEN: 10,
	OptionIndex.WHITE_CHICKEN: 15,
	OptionIndex.AREA1: 50,
	OptionIndex.AREA2: 100,
	OptionIndex.AREA3: 250,
	OptionIndex.AREA4: 450,
	OptionIndex.LAY_SPEED: 300,
	OptionIndex.SUPPLY: 800,
	OptionIndex.GOLDEN_FEED: 500,
	OptionIndex.CUP: 5000,
	OptionIndex.FEED: 10,
}
var feed_cost_golden := Global.golden_egg_chickens_threshold * Global.golden_egg_value

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	populate_menu()
	feed_button.pressed.connect(_on_feed_pressed)
	feed_timer.timeout.connect(_update_purchase)
	Global.eggs_changed.connect(_on_eggs_changed)
	Global.chickens_changed.connect(_on_chickens_or_supply_changed)
	Global.supply_changed.connect(_on_chickens_or_supply_changed)
	victory.hide()
	victory_button.pressed.connect(victory.hide)

const format_item := "[%d] %s"
func add_icon_item(icon: Texture2D, txt: String, id: OptionIndex, key : Key = KEY_NONE) -> void:
		menu.add_icon_item(icon, format_item % [costs[id], txt], id, key)
func add_item(txt: String, id: OptionIndex, key : Key = KEY_NONE) -> void:
		menu.add_item(format_item % [costs[id], txt], id, key)
	
func populate_menu() -> void:
	menu.add_separator("Chickens")
	add_icon_item(brown_chicken_icon, "Brown Chicken (1 egg/laying)", OptionIndex.BROWN_CHICKEN, KEY_B)
	add_icon_item(white_chicken_icon, "White Chicken (2 egg/laying)", OptionIndex.WHITE_CHICKEN, KEY_W)
	menu.add_separator("Expand Pen")
	add_icon_item(fence_icon, "Tender Grass", OptionIndex.AREA1, KEY_E)
	add_icon_item(fence_icon, "Cozy Nests ", OptionIndex.AREA2, KEY_E)
	add_icon_item(fence_icon, "Tiny Lake", OptionIndex.AREA3, KEY_E)
	add_icon_item(fence_icon, "Green Meadow", OptionIndex.AREA4, KEY_E)
	menu.add_separator("Upgrades")
	add_icon_item(flower_icon, upgrade_desc_text[OptionIndex.LAY_SPEED], OptionIndex.LAY_SPEED)
	add_icon_item(golden_nuggets_icon, upgrade_desc_text[OptionIndex.GOLDEN_FEED], OptionIndex.GOLDEN_FEED)
	add_icon_item(water_cup_icon, upgrade_desc_text[OptionIndex.SUPPLY], OptionIndex.SUPPLY)
	menu.add_separator("Trophy")
	add_item("Chicken Spring Cup", OptionIndex.CUP)
	menu.id_pressed.connect(_on_purchase)
	feed_button.text = "[%d] Feed" % [costs[OptionIndex.FEED]]
	_update_purchase()

func _on_eggs_changed(eggs: int) -> void:
	eggs_label.text = str(eggs)
	_update_purchase()

func _update_purchase() -> void:
	menu.set_item_disabled(
		menu.get_item_index(OptionIndex.BROWN_CHICKEN),
		costs[OptionIndex.BROWN_CHICKEN] > Global.eggs or Global.supply < Global.chickens + Global.spawn_count
	)
	menu.set_item_disabled(
		menu.get_item_index(OptionIndex.WHITE_CHICKEN),
		costs[OptionIndex.WHITE_CHICKEN] > Global.eggs or Global.supply < Global.chickens + Global.spawn_count
	)
	var upgrade_option : Array[OptionIndex] = [
		OptionIndex.LAY_SPEED, OptionIndex.SUPPLY, OptionIndex.GOLDEN_FEED
	]
	var upgrade_available := {
		OptionIndex.LAY_SPEED: true,
		OptionIndex.SUPPLY: Global.unlocked_area >= 4,
		OptionIndex.GOLDEN_FEED: Global.chickens >= 50
	}
	for i in len(upgrade_option):
		var id := upgrade_option[i]
		var index := menu.get_item_index(id)
		menu.set_item_disabled(
			index,
			costs[id] > Global.eggs or Global.upgrade_unlocked.has(id) or not upgrade_available[id]
		)
		menu.set_item_text(
			index,
			format_item % [costs[id], upgrade_desc_text[id]]
			if upgrade_available[id] else upgrade_cond_text[id]
		)
	
	var area_option : Array[OptionIndex] = [
		OptionIndex.AREA1, OptionIndex.AREA2, OptionIndex.AREA3, OptionIndex.AREA4
	]
	for i in len(area_option):
		var id := area_option[i]
		var index := menu.get_item_index(id)
		var disabled : bool = costs[id] > Global.eggs or Global.unlocked_area != i
		menu.set_item_disabled(index, disabled)
		menu.set_item_accelerator(index, KEY_NONE if Global.unlocked_area != i else KEY_E)
	menu.set_item_disabled(menu.get_item_index(OptionIndex.CUP), costs[OptionIndex.CUP] > Global.eggs)
	feed_button.disabled = costs[OptionIndex.FEED] > Global.eggs or not feed_timer.is_stopped()

func _on_chickens_or_supply_changed(_unused: int) -> void:
	chickens_label.text = "%d/%d" % [Global.chickens, Global.supply]
	_update_purchase()

func _on_golden_feed_unlocked() -> void:
	Global.golden_feed = true
	costs[OptionIndex.FEED] = feed_cost_golden
	feed_button.icon = golden_nuggets_icon
	feed_button.text = "[%d] Feed" % [costs[OptionIndex.FEED]]
	feed_button.tooltip_text = "GOLDEN egg on next laying\nfor all chickens\n(1 golden egg = %s eggs)\n[Shortcut F]" % [
		Global.golden_egg_value
	]
	_update_purchase()

func _on_purchase(id: int) -> void:
	Global.eggs -= costs[id]
	match id:
		OptionIndex.BROWN_CHICKEN:
			spawn_chicken.emit(Global.ChickenType.BROWN)
		OptionIndex.WHITE_CHICKEN:
			spawn_chicken.emit(Global.ChickenType.WHITE)
		OptionIndex.AREA1:
			unlock_area.emit(1)
		OptionIndex.AREA2:
			unlock_area.emit(2)
		OptionIndex.AREA3:
			unlock_area.emit(3)
		OptionIndex.AREA4:
			unlock_area.emit(4)
		OptionIndex.LAY_SPEED:
			Global.upgrade_unlocked.append(OptionIndex.LAY_SPEED)
			Global.laying_period /= 1.3
			unlock_flowers.emit()
			_update_purchase()
		OptionIndex.SUPPLY:
			Global.upgrade_unlocked.append(OptionIndex.SUPPLY)
			Global.supply_per_cell *= 1.5
			unlock_water_cups.emit()
			_update_purchase()
		OptionIndex.GOLDEN_FEED:
			Global.upgrade_unlocked.append(OptionIndex.GOLDEN_FEED)
			_on_golden_feed_unlocked()
			_update_purchase()
		OptionIndex.CUP:
			victory.show()
			($VictoryContainer/VictoryAudio as AudioStreamPlayer).play()
			unlock_cup.emit()
		OptionIndex.FEED:
			feed_timer.start(Global.laying_period * (1.5 if Global.golden_feed else 1.0))
			feed.emit(Global.golden_feed)
			_update_purchase()

func _on_feed_pressed():
	_on_purchase(OptionIndex.FEED)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("feed"):
		if not feed_button.disabled:
			_on_feed_pressed()
