
extends Node2D

signal key_pressed()

const Chicken := preload("res://scenes/Chicken.tscn")
@onready var tile_map := $TileMap as PenMap
@onready var hud := $CanvasLayer/HUD as HUD
var chickens : Array[Chicken] = []

func _ready():
	const b := Global.ChickenType.BROWN
	for t in [b, b, b, b, Global.ChickenType.WHITE]:
		_spawn_chicken(t)
	hud.spawn_chicken.connect(func(t):
		_spawn_chicken(t)
		chickens[-1].start_laying()
	)
	hud.feed.connect(func(_golden_feed):
		for c in chickens:
			c.feed()
	)
	hud.unlock_area.connect(tile_map.unlock_area)
	hud.unlock_cup.connect(_on_unlock_cup)
	hud.unlock_flowers.connect(tile_map.spawn_flowers)
	hud.unlock_water_cups.connect(tile_map.spawn_water_cups)
	Global.eggs = Global.starting_eggs
	if not Global.skip_intro:
		await _play_intro()
	for c in chickens:
		c.start_laying()

func _play_intro() -> void:
	get_tree().paused = true
	# hide overlay
	($CanvasLayer/HUD/IntroOverlay as Control).show()
	var labels : Array[Label] = []
	for c in $CanvasLayer/HUD/IntroOverlay/CenterContainer/VBoxContainer.get_children():
		if c is Label:
			(c as Label).modulate.a = 0.0
			labels.append(c)
	# animate texts
	var t := create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	for c in labels:
		if c.name == "ChickenLabel":
			t.play()
			await t.finished
			get_tree().paused = false
			($BirdsPlayer as AudioStreamPlayer).volume_db -= 7
			t = create_tween()
			t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		t.tween_property(c, "modulate", Color.WHITE, 1.0)
		if c != labels[-1]:
			t.tween_property(c, "modulate", Color(1,1,1,0.9), 1.5)
	t.play()
	await t.finished
	# press key to continue 
	await key_pressed
	labels[-1].modulate.a = 0
	# hide overlay
	t = create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property($CanvasLayer/HUD/IntroOverlay, "modulate", Color(0, 0, 0, 0.01), 2.5).set_ease(Tween.EASE_IN)
	for c in labels:
		t.parallel().tween_property(c, "modulate", Color(1,1,1,0.0), 0.7)
	t.play()
	await t.finished
	($CanvasLayer/HUD/IntroOverlay as Control).hide()

func _spawn_chicken(type: Global.ChickenType) -> void:
	var c := tile_map.get_spawn_location()
	var chicken := Chicken.instantiate() as Chicken
	chicken.position = (Vector2(c) + Vector2(randf(), randf())) * Vector2(tile_map.tile_set.tile_size)
	tile_map.add_child(chicken)
	chicken.type = type
	Global.chickens += 1
	chickens.append(chicken)
	($BirdsPlayer as AudioStreamPlayer).volume_db -= 1

func _on_unlock_cup() -> void:
	for c in chickens:
		c.victory_dance()

func _unhandled_key_input(_event: InputEvent) -> void:
	key_pressed.emit()
