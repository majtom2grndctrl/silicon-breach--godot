extends Node
class_name GameStateSystemRuntime

signal scenario_loaded(scenario_path: String)

@export var auto_start: bool = true
@export var default_scenario_path: String = "res://scenarios/chip_delivery/scenario.json"
@export var remove_title_screen: bool = true
@export var player_scene_path: String = "res://entities/Player.tscn"
@export var kess_scene_path: String = "res://entities/Kess_the_Fixer.tscn"
@export var title_scene_path: String = "res://ui/TitleScreen.tscn"
@export var dialog_ui_scene_path: String = "res://ui/DialogBox.tscn"
@export var hud_scene_path: String = "res://ui/HUD.tscn"
@export var demo_prompt_scene_path: String = "res://ui/DemoCompletePrompt.tscn"

var current_map: Node3D = null

func _ready() -> void:
	if auto_start:
		load_scenario(default_scenario_path)

func load_scenario(scenario_path: String) -> void:
	var scenario_data: Dictionary = _load_scenario_data(scenario_path)
	if scenario_data.is_empty():
		return
	var map_path: String = String(scenario_data.get("starting_map", ""))
	if map_path == "":
		return
	var map_scene: PackedScene = load(map_path) as PackedScene
	if map_scene == null:
		return
	var map_instance: Node3D = map_scene.instantiate() as Node3D
	if map_instance == null:
		return
	if current_map and is_instance_valid(current_map):
		current_map.queue_free()
	current_map = map_instance
	get_tree().root.add_child.call_deferred(current_map)
	call_deferred("_post_load_scenario", scenario_path, scenario_data)

func _post_load_scenario(scenario_path: String, scenario_data: Dictionary) -> void:
	if current_map == null or not current_map.is_inside_tree():
		call_deferred("_post_load_scenario", scenario_path, scenario_data)
		return
	if remove_title_screen:
		var title: Node = get_tree().root.get_node_or_null("TitleScreen")
		if title:
			title.queue_free()
	_spawn_ui()
	_spawn_player()
	_spawn_kess()
	_assign_initial_jobs(scenario_data)
	scenario_loaded.emit(scenario_path)

func get_current_map() -> Node3D:
	return current_map

func _load_scenario_data(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		return {}
	var data: Variant = json.data
	if data is Dictionary:
		return data
	return {}

func _spawn_player() -> void:
	var map: Node3D = current_map
	if map == null:
		return
	if map.get_node_or_null("Player") != null:
		return
	var packed: PackedScene = load(player_scene_path) as PackedScene
	if packed == null:
		return
	var player: CharacterBody3D = packed.instantiate() as CharacterBody3D
	if player == null:
		return
	player.name = "Player"
	map.add_child(player)
	var spawn: Marker3D = map.get_node_or_null("PlayerSpawn") as Marker3D
	if spawn:
		player.global_position = spawn.global_position

func _spawn_kess() -> void:
	var map: Node3D = current_map
	if map == null:
		return
	if map.get_node_or_null("Kess_the_Fixer") != null:
		return
	var packed: PackedScene = load(kess_scene_path) as PackedScene
	if packed == null:
		return
	var kess: CharacterBody3D = packed.instantiate() as CharacterBody3D
	if kess == null:
		return
	kess.name = "Kess_the_Fixer"
	map.add_child(kess)
	var spawn: Marker3D = map.get_node_or_null("KessSpawn") as Marker3D
	if spawn:
		kess.global_position = spawn.global_position

func _assign_initial_jobs(scenario_data: Dictionary) -> void:
	var player_state: PlayerStateComponent = _get_player_state()
	if player_state == null:
		return
	var initial_jobs: Variant = scenario_data.get("initial_player_jobs", [])
	if not (initial_jobs is Array):
		return
	for job_path in initial_jobs:
		if job_path is String:
			var job: Job = _load_job(job_path)
			if job:
				player_state.active_jobs.append(job)
				var spawning: SpawningSystemRuntime = get_node_or_null("/root/SpawningSystem") as SpawningSystemRuntime
				if spawning:
					spawning.initialize_job(job)

func return_to_title() -> void:
	if current_map and is_instance_valid(current_map):
		current_map.queue_free()
	current_map = null
	_clear_ui()
	_spawn_title()

func _spawn_title() -> void:
	if get_tree().root.get_node_or_null("TitleScreen") != null:
		return
	var packed: PackedScene = load(title_scene_path) as PackedScene
	if packed == null:
		return
	var title: Control = packed.instantiate() as Control
	if title == null:
		return
	title.name = "TitleScreen"
	get_tree().root.add_child(title)

func _spawn_ui() -> void:
	_spawn_ui_scene(dialog_ui_scene_path, "DialogBox")
	_spawn_ui_scene(hud_scene_path, "HUD")
	_spawn_ui_scene(demo_prompt_scene_path, "DemoCompletePrompt")

func _spawn_ui_scene(path: String, node_name: String) -> void:
	if get_tree().root.get_node_or_null(node_name) != null:
		return
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return
	var instance: Control = packed.instantiate() as Control
	if instance == null:
		return
	instance.name = node_name
	get_tree().root.add_child(instance)

func _clear_ui() -> void:
	for node_name in ["DialogBox", "HUD", "DemoCompletePrompt"]:
		var node := get_tree().root.get_node_or_null(node_name)
		if node:
			node.queue_free()

func _load_job(path: String) -> Job:
	var resource: Job = load(path) as Job
	if resource == null:
		return null
	var job: Job = resource.duplicate(true) as Job
	if job == null:
		return null
	job.status = "active"
	return job

func _get_player_state() -> PlayerStateComponent:
	var nodes: Array[Node] = get_tree().root.find_children("", "ComponentHost", true, false)
	for node in nodes:
		var host: ComponentHost = node as ComponentHost
		if host and host.has_component(&"PlayerStateComponent"):
			return host.get_component(&"PlayerStateComponent") as PlayerStateComponent
	return null
