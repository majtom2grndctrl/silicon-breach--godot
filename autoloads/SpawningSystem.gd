extends Node
class_name SpawningSystemRuntime

@export var chip_scene_path: String = "res://entities/chip_item.tscn"

func _ready() -> void:
	var dialog: DialogSystemRuntime = get_node_or_null("/root/DialogSystem") as DialogSystemRuntime
	if dialog:
		dialog.job_accepted.connect(_on_job_accepted)

func initialize_job(job: Job) -> void:
	if job == null:
		return
	if job.objective_instances.is_empty():
		job.objective_instances = _resolve_objectives(job)
	if job.objective_statuses.is_empty():
		for objective in job.objective_instances:
			if objective and objective.id != "":
				job.objective_statuses[objective.id] = "active"
	_spawn_for_job(job)

func _on_job_accepted(job: Job) -> void:
	initialize_job(job)

func _resolve_objectives(job: Job) -> Array:
	var resolved: Array = []
	for entry in job.objectives:
		if entry is Objective:
			resolved.append((entry as Objective).duplicate(true))
		elif entry is String:
			var loaded := load(entry) as Objective
			if loaded:
				resolved.append(loaded.duplicate(true))
	return resolved

func _spawn_for_job(job: Job) -> void:
	if job.id != "chip_delivery":
		return
	var map: Node3D = _get_current_map()
	if map == null:
		return
	var pickup_marker: Marker3D = _find_spawn_marker(map, "pickup")
	var delivery_marker: Marker3D = _find_spawn_marker(map, "delivery")
	if pickup_marker:
		_spawn_chip(pickup_marker)
	for objective in job.objective_instances:
		if objective == null:
			continue
		for rule in objective.completion_rules:
			if rule is Dictionary:
				if rule.get("type") == "item_delivered" and rule.get("marker_id", "") == "":
					if delivery_marker:
						rule["marker_id"] = delivery_marker.name
		if objective.type == "item_in_inventory" and objective.target_ref == "":
			objective.target_ref = chip_scene_path

func _spawn_chip(marker: Marker3D) -> void:
	var map: Node3D = marker.get_parent() as Node3D
	if map == null:
		return
	if map.find_child("chip_item", true, false):
		return
	var packed: PackedScene = load(chip_scene_path) as PackedScene
	if packed == null:
		return
	var chip: Node3D = packed.instantiate() as Node3D
	if chip == null:
		return
	map.add_child(chip)
	chip.global_position = marker.global_position

func _find_spawn_marker(map: Node, pool_name: String) -> Marker3D:
	var nodes: Array[Node] = map.find_children("", "ComponentHost", true, false)
	for node in nodes:
		if node is Marker3D:
			var marker: Marker3D = node as Marker3D
			var host: ComponentHost = node as ComponentHost
			if host and host.has_component(&"ObjectiveSpawnPointComponent"):
				var comp := host.get_component(&"ObjectiveSpawnPointComponent") as ObjectiveSpawnPointComponent
				if comp and comp.pool_name == pool_name:
					return marker
	return null

func _get_current_map() -> Node3D:
	var state: GameStateSystemRuntime = get_node_or_null("/root/GameStateSystem") as GameStateSystemRuntime
	if state:
		return state.get_current_map()
	return null
