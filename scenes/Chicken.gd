class_name Chicken
extends CharacterBody2D

const WhiteSprites := preload("res://assets/images/chicken-white.tres")

enum State {NONE, RANDOM_WALK, GO_TO_EAT, EAT, SEAT, IDLE, JUMP}

const audio_cooldown := 6.0
const eat_duration := 1.0
const seat_duration := 3.0
const idle_duration := 1.0
const jump_duration := 10.0
const SPEED := 20.0
const HURRY_SPEED := 30.0

@onready var sprite := $AnimatedSprite2D as AnimatedSprite2D
@onready var base_scale := sprite.scale
@onready var timer := $Timer as Timer
@onready var laying_timer := $LayingTimer as Timer
@onready var audio_timer := $AudioTimer as Timer
var state := State.IDLE
var target_position := Vector2.ZERO
var speed := SPEED
var next_laying_bonus := false
var type := Global.ChickenType.WHITE: set=set_type
var next_action := State.NONE

func set_type(t: Global.ChickenType) -> void:
	type = t
	if t == Global.ChickenType.WHITE:
		sprite.sprite_frames = WhiteSprites

func _ready():
	sprite.flip_h = randi_range(0, 1)
	timer.timeout.connect(_on_timeout)
	laying_timer.timeout.connect(_on_laying_timeout)
	audio_timer.timeout.connect(_on_audio_timeout)
	execute_idle()
	audio_timer.start(randf_range(0.0, audio_cooldown * 1.2))
	
func start_laying() -> void:
	laying_timer.start(randfn(2 * Global.laying_period, Global.laying_period * 0.1))


func execute_idle() -> void:
	state = State.IDLE
	sprite.play("idle")
	sprite.set_frame_and_progress(randi_range(0, 1), randf())
	timer.start(randfn(idle_duration, idle_duration * 0.3))

func execute_random_walk() -> void:
	state = State.RANDOM_WALK
	speed = SPEED
	sprite.play("walk")
	var side := randi_range(0, 1)
	var angle := randf_range(-PI / 3, PI / 3) + (1 - side) * PI
	var dir := Vector2.from_angle(angle)
	var distance := randfn(100, 50)
	target_position = position + dir * distance
	timer.start(distance / speed)
	sprite.flip_h = (side == 0)

func execute_eat() -> void:
	state = State.EAT
	sprite.play("eat")
	timer.start(randfn(eat_duration, eat_duration * 0.3))

func execute_seat() -> void:
	state = State.SEAT
	sprite.play("seat")
	timer.start(randfn(seat_duration, seat_duration * 0.3))

func execute_jump() -> void:
	state = State.JUMP
	sprite.play("jump")
	sprite.set_frame_and_progress(randi_range(0, 2), randf())
	timer.start(randfn(jump_duration, jump_duration * 0.3))

func _on_timeout():
	if next_action != State.NONE:
		match next_action:
			State.JUMP:
				execute_jump()
			State.RANDOM_WALK:
				execute_random_walk()
			State.IDLE:
				execute_idle()
			State.EAT:
				execute_eat()
			State.SEAT:
				execute_seat()
		next_action = State.NONE
	else:
		match state:
			State.IDLE, State.RANDOM_WALK, State.EAT, State.SEAT:
				match randi_range(0, 4):
					0, 1:
						execute_random_walk()
					2:
						execute_idle()
					3:
						execute_eat()
					4:
						execute_seat()
			_:
				pass


func _on_audio_timeout() -> void:
	var all := state == State.EAT or state == State.GO_TO_EAT
	var audio := $Audios.get_child(
		randi_range(
			int(randf() > 0.2 and not all),
			$Audios.get_child_count() - 1 - int(randf() > 0.3 and not all)
		) if not all or randf() > 0.1 else 0
	) as AudioStreamPlayer2D
		
	audio.play()
	audio_timer.start(randfn(audio_cooldown, audio_cooldown * 0.2))
	
func _on_laying_timeout() -> void:
	if Global.golden_feed and next_laying_bonus:
		Global.eggs += Global.golden_egg_value
		($AnimatedSprite2D/EggPopSprite as AnimatedSprite2D).play("golden")
	else:
		var c := 1 + int(type == Global.ChickenType.WHITE) + int(next_laying_bonus)
		Global.eggs += c
		($AnimatedSprite2D/EggPopSprite as AnimatedSprite2D).play("egg"+str(clampi(c, 1, 3)))
	($AnimatedSprite2D/EggPopSprite/AnimationPlayer as AnimationPlayer).play("pop")
	next_laying_bonus = false
	laying_timer.start(randfn(Global.laying_period, Global.laying_period * 0.1))

func move_to_target_position(_delta: float) -> void:
	var dir := position.direction_to(target_position)
	var dist := position.distance_to(target_position)
	velocity = dir * SPEED * clampf(inverse_lerp(0, 20, dist), 0.0, 1.0)
	var _collide := move_and_slide()

func _physics_process(delta: float) -> void:
	match state:
		State.RANDOM_WALK, State.GO_TO_EAT:
			move_to_target_position(delta)
		_:
			pass

func victory_dance() -> void:
	timer.stop()
	next_action = State.JUMP
	_on_timeout()

func feed() -> void:
	next_laying_bonus = true
	var t := fmod(timer.wait_time, 2.0) + 0.3
	timer.start(t)
	next_action = State.EAT
