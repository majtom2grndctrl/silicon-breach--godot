extends Node
class_name InteractionSystemRuntime

signal interaction_target_changed(target: Node3D, prompt: String)
signal interaction_target_cleared()
signal interaction_triggered(target: Node3D)
signal item_taken(item_id: String)
signal item_delivered(item_id: String, marker_id: String)

@export var interaction_range: float = 2.5
@export var delivery_prompt: String = "Deliver Chip"
@export var chip_item_path: String = "res://entities/chip_item.tscn"

var current_target: Node3D = null
var current_prompt: String = ""

func _process(_delta: float) -> void:
	var player: CharacterBody3D = _get_player_node()
	if player == null:
		_clear_target()
		return
	var sensor: Area3D = player.get_node_or_null("InteractionSensor") as Area3D
	var camera: Camera3D = player.get_node_or_null("CameraPivot/SpringArm3D/Camera3D") as Camera3D
	if sensor == null or camera == null:
		_clear_target()
		return
	_update_target(player, sensor, camera)
	if Input.is_action_just_pressed("interact") and current_target != null:
		_handle_interaction(player, current_target)

func _update_target(player: CharacterBody3D, sensor: Area3D, camera: Camera3D) -> void:
	var candidates: Array[Node3D] = []
	for body in sensor.get_overlapping_bodies():
		if body is Node3D:
			var target := _resolve_interaction_target(body)
			if target:
				candidates.append(target)
	for area in sensor.get_overlapping_areas():
		if area is Node3D:
			var target := _resolve_interaction_target(area)
			if target:
				candidates.append(target)
	var best: Node3D = _pick_best_target(player, camera, candidates)
	if best != current_target:
		current_target = best
		current_prompt = _get_prompt_for_target(best) if best else ""
		if best:
			interaction_target_changed.emit(best, current_prompt)
		else:
			interaction_target_cleared.emit()

func _pick_best_target(player: CharacterBody3D, camera: Camera3D, candidates: Array[Node3D]) -> Node3D:
	var best: Node3D
	var best_distance := INF
	var best_screen_distance := INF
	var center := get_viewport().get_visible_rect().size * 0.5
	for candidate in candidates:
		var distance := player.global_position.distance_to(candidate.global_position)
		if distance > interaction_range:
			continue
		if not _has_line_of_sight(camera, player, candidate):
			continue
		var screen_distance := center.distance_to(camera.unproject_position(candidate.global_position))
		if distance < best_distance - 0.05:
			best_distance = distance
			best_screen_distance = screen_distance
			best = candidate
		elif abs(distance - best_distance) <= 0.05 and screen_distance < best_screen_distance:
			best_screen_distance = screen_distance
			best = candidate
	return best

func _resolve_interaction_target(node: Node3D) -> Node3D:
	var host: ComponentHost = _find_component_host(node)
	if host == null:
		return null
	if host.has_component(&"InteractionComponent"):
		return node
	if host.has_component(&"ObjectiveSpawnPointComponent"):
		return node
	return null

func _get_prompt_for_target(target: Node3D) -> String:
	if target == null:
		return ""
	var host: ComponentHost = _find_component_host(target)
	if host and host.has_component(&"InteractionComponent"):
		var interaction := host.get_component(&"InteractionComponent") as InteractionComponent
		if interaction:
			return interaction.interaction_prompt
	if host and host.has_component(&"ObjectiveSpawnPointComponent"):
		var spawn_point := host.get_component(&"ObjectiveSpawnPointComponent") as ObjectiveSpawnPointComponent
		if spawn_point and spawn_point.pool_name == "delivery":
			return delivery_prompt
	return ""

func _handle_interaction(player: CharacterBody3D, target: Node3D) -> void:
	interaction_triggered.emit(target)
	var host: ComponentHost = _find_component_host(target)
	if host == null:
		return
	var player_host: ComponentHost = _find_component_host(player)
	if player_host == null or not player_host.has_component(&"PlayerStateComponent"):
		return
	var player_state := player_host.get_component(&"PlayerStateComponent") as PlayerStateComponent
	if player_state == null or player_state.inventory == null:
		return
	if host.has_component(&"ObjectiveSpawnPointComponent"):
		_try_deliver_item(player_state, host, target)
	if host.has_component(&"InteractionComponent"):
		_try_take_item(player_state, target)

func _try_take_item(player_state: PlayerStateComponent, target: Node3D) -> void:
	if chip_item_path == "":
		return
	if target.scene_file_path != chip_item_path:
		return
	var packed := load(chip_item_path) as PackedScene
	if packed == null:
		return
	player_state.inventory.items.append(packed)
	item_taken.emit(chip_item_path)
	target.queue_free()

func _try_deliver_item(player_state: PlayerStateComponent, host: ComponentHost, target: Node3D) -> void:
	var spawn_point := host.get_component(&"ObjectiveSpawnPointComponent") as ObjectiveSpawnPointComponent
	if spawn_point == null or spawn_point.pool_name != "delivery":
		return
	var index := _find_item_index(player_state.inventory.items, chip_item_path)
	if index == -1:
		return
	player_state.inventory.items.remove_at(index)
	item_delivered.emit(chip_item_path, target.name)

func _find_item_index(items: Array, path: String) -> int:
	for i in range(items.size()):
		var packed := items[i] as PackedScene
		if packed and packed.resource_path == path:
			return i
	return -1

func _has_line_of_sight(camera: Camera3D, player: CharacterBody3D, target: Node3D) -> bool:
	var world := camera.get_world_3d()
	if world == null:
		return true
	var space_state: PhysicsDirectSpaceState3D = world.direct_space_state
	var params := PhysicsRayQueryParameters3D.create(camera.global_position, target.global_position)
	params.exclude = [player]
	var result: Dictionary = space_state.intersect_ray(params)
	if result.is_empty():
		return true
	var collider: Object = result.get("collider")
	if collider == target:
		return true
	if collider is Node and (collider as Node).is_ancestor_of(target):
		return true
	if target.is_ancestor_of(collider):
		return true
	return false

func _get_player_node() -> CharacterBody3D:
	var nodes: Array[Node] = get_tree().get_root().find_children("", "ComponentHost", true, false)
	for node in nodes:
		var host: ComponentHost = node as ComponentHost
		if host and host.has_component(&"PlayerStateComponent") and node is CharacterBody3D:
			return node as CharacterBody3D
	return null

func _find_component_host(node: Node) -> ComponentHost:
	var current: Node = node
	while current:
		if current is ComponentHost:
			return current as ComponentHost
		current = current.get_parent()
	return null

func _clear_target() -> void:
	if current_target != null:
		current_target = null
		current_prompt = ""
		interaction_target_cleared.emit()
