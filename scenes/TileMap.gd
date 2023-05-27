class_name PenMap
extends TileMap

const W := 16
const H := 12
const RECT := Rect2i(0, 0, W, H)
const UNKNOWN := -2
const FENCE := -1
const OWNED_AREA := 0

var seed_area : Array[Vector2i] = [
	Vector2i(1, 1),
	Vector2i(1, 5),
	Vector2i(1, 8),
	Vector2i(8, 8),
	Vector2i(8, 1),
]
var size_area : Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
var map_area := PackedInt32Array()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(len(size_area) == 5)
	assert(len(seed_area) == 5)
	map_area.resize(W * H)
	map_area.fill(UNKNOWN)
	for i in range(len(seed_area)):
		dfs_fill_area(seed_area[i], i)
	Global.owned_cells = size_area[0]
	print(size_area)

func print_map() -> void:
	print(size_area)
	for y in H:
		var s:=""
		for x in W:
			s+=str(map_area[to_index(Vector2i(x,y))]+2)
		print(s)
	

func dfs_fill_area(c: Vector2i, area_index: int) -> void:
	var t := get_cell_tile_data(0, c)
	if map_area[to_index(c)] != UNKNOWN:
		pass
	elif t != null and t.get_custom_data("is_fence") == true:
		map_area[to_index(c)] = FENCE
	else:
		map_area[to_index(c)] = area_index
		size_area[area_index] += t.get_custom_data("usable") if t != null else 1.0
		dfs_fill_area(c + Vector2i.LEFT, area_index)
		dfs_fill_area(c + Vector2i.RIGHT, area_index)
		dfs_fill_area(c + Vector2i.UP, area_index)
		dfs_fill_area(c + Vector2i.DOWN, area_index)

func to_index(c : Vector2i) -> int:
	return c.x + c.y * W

func to_cell(i: int) -> Vector2i:
	return Vector2i(i % W, int(i / W))

func neighbor_count(c : Vector2i) -> Array[int]:
	var counts : Array[int] = []
	counts.resize(len(seed_area))
	counts.fill(0)
	for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if RECT.has_point(c+d):
			var area_index := map_area[to_index(c+d)]
			if area_index >= OWNED_AREA:
				counts[area_index] += 1
	return counts

func unlock_area(area_index: int) -> void:
	size_area[OWNED_AREA] += size_area[area_index]
	size_area[area_index] = 0.0
	# assign new area OWNED
	for i in range(len(map_area)):
		if map_area[i] == area_index:
			map_area[i] = OWNED_AREA
	# remove fence
	var fence_removed := true
	var remove_pos : Array[Vector2i] = []
	while fence_removed:
		fence_removed = false
		for i in range(len(map_area)):
			var c := to_cell(i)
			if map_area[i] == FENCE:
				for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					if (
						RECT.has_point(c+Vector2i.LEFT) and RECT.has_point(c+Vector2i.RIGHT)
						and map_area[to_index(c+Vector2i.LEFT)] == OWNED_AREA
						and map_area[to_index(c+Vector2i.RIGHT)] == OWNED_AREA
					) or (
						RECT.has_point(c+Vector2i.UP) and RECT.has_point(c+Vector2i.DOWN)
						and map_area[to_index(c+Vector2i.UP)] == OWNED_AREA
						and map_area[to_index(c+Vector2i.DOWN)] == OWNED_AREA
					):
						map_area[i] = OWNED_AREA
						size_area[OWNED_AREA] += 1.0
						erase_cell(0, c)
						fence_removed = true
						remove_pos.append(c)
	Global.unlocked_area = area_index
	Global.owned_cells = size_area[0]
	($DestroyAudio as AudioStreamPlayer).play()
	_dust_burst(remove_pos)

func _has_tile_collision(c: Vector2i) -> bool:
	var t := get_cell_tile_data(0, c)
	return t != null and t.get_custom_data("usable") < 0.9

func get_spawn_location() -> Vector2i:
	var owned := 0
	for i in range(len(map_area)):
		owned += int(map_area[i] == OWNED_AREA and not _has_tile_collision(to_cell(i)))
	var r := randi_range(0, owned - 1)
	var c := Vector2i.ONE
	for i in range(len(map_area)):
		if map_area[i] == OWNED_AREA and not _has_tile_collision(to_cell(i)):
			owned -= 1
			if owned == r:
				c = to_cell(i)
	return c

func _free_tile_count() -> int:
	var free := 0
	for i in range(len(map_area)):
		var t := get_cell_tile_data(0, to_cell(i))
		free += int(t == null)
	return free

func spawn_flowers() -> void:
	var count := 10
	var free := _free_tile_count()
	var proba := float(count) / float(free)
	var pos : Array[Vector2i] = []
	for i in range(len(map_area)):
		var t := get_cell_tile_data(0, to_cell(i))
		if t == null and randf() < proba:
			set_cell(0, to_cell(i), 0, Vector2i(randi_range(0, 2), 3))
			pos.append(to_cell(i))
			count -= 1
			if count == 0:
				break
	($SpawnAudio as AudioStreamPlayer).play()
	_dust_burst(pos)

func spawn_water_cups() -> void:
	var count := 5
	var free := _free_tile_count()
	var proba := float(count) / float(free)
	var pos : Array[Vector2i] = []
	for i in range(len(map_area)):
		var t := get_cell_tile_data(0, to_cell(i))
		if t == null and randf() < proba:
			set_cell(0, to_cell(i), 0, Vector2i(4, 3))
			pos.append(to_cell(i))
			count -= 1
			if count == 0:
				break
	($SpawnAudio as AudioStreamPlayer).play()
	_dust_burst(pos)

func _dust_burst(pos: Array[Vector2i]) -> void:
	pos.shuffle()
	for i in range(min(len(pos), $Particles.get_child_count())):
		var particles := $Particles.get_child(i) as CPUParticles2D
		particles.position = map_to_local(pos[i])
		particles.emitting = true
