extends Node
class_name DialogSystemRuntime

signal dialog_started(tree: DialogTree, npc: Node3D)
signal dialog_ended()
signal dialog_node_reached(node_id: String)
signal dialog_event_emitted(event_id: String, payload: Dictionary)
signal job_accepted(job: Job)
signal job_completed(job: Job)

var active_tree: DialogTree = null
var active_node: Dictionary = {}
var active_npc: Node3D = null

func _ready() -> void:
	var interaction: InteractionSystemRuntime = get_node_or_null("/root/InteractionSystem") as InteractionSystemRuntime
	if interaction:
		interaction.interaction_triggered.connect(_on_interaction_triggered)

func _unhandled_input(event: InputEvent) -> void:
	if active_tree == null:
		return
	if active_node.is_empty():
		return
	var choices: Array = active_node.get("choices", [])
	if choices is Array and choices.size() > 0:
		var choice_index: int = -1
		if Input.is_action_just_pressed("dialog_choice_1"):
			choice_index = 0
		elif Input.is_action_just_pressed("dialog_choice_2"):
			choice_index = 1
		elif Input.is_action_just_pressed("dialog_choice_3"):
			choice_index = 2
		elif Input.is_action_just_pressed("dialog_choice_4"):
			choice_index = 3
		if choice_index >= 0 and choice_index < choices.size():
			_choose_choice(choices[choice_index])
	else:
		if Input.is_action_just_pressed("dialog_next") or Input.is_action_just_pressed("ui_accept"):
			var next_id := String(active_node.get("next_node_id", ""))
			if next_id != "":
				_enter_node(next_id)
			else:
				_end_dialog()

func _on_interaction_triggered(target: Node3D) -> void:
	if target == null:
		return
	var host: ComponentHost = _find_component_host(target)
	if host == null:
		return
	if not host.has_component(&"NPCStateComponent"):
		return
	var npc_state: NPCStateComponent = host.get_component(&"NPCStateComponent") as NPCStateComponent
	if npc_state == null or npc_state.dialog_tree == null:
		return
	start_dialog(npc_state.dialog_tree as DialogTree, target)

func start_dialog(tree: DialogTree, npc: Node3D) -> void:
	active_tree = tree
	active_npc = npc
	var start_id: String = _select_start_node(tree)
	dialog_started.emit(tree, npc)
	_enter_node(start_id)

func _select_start_node(tree: DialogTree) -> String:
	var player_state: PlayerStateComponent = _get_player_state()
	if player_state:
		var job: Job = _find_job_by_id(player_state.active_jobs, "chip_delivery")
		if job and job.status == "awaiting_turn_in":
			if not _find_node(tree, "turn_in").is_empty():
				return "turn_in"
	return tree.start_node_id

func _enter_node(node_id: String) -> void:
	var node: Dictionary = _find_node(active_tree, node_id)
	if node.is_empty():
		_end_dialog()
		return
	active_node = node
	dialog_node_reached.emit(node_id)
	var events: Array = node.get("events", [])
	if events is Array:
		for event in events:
			_apply_event(event)

func _choose_choice(choice: Dictionary) -> void:
	var event: Variant = choice.get("event")
	if event != null:
		_apply_event(event)
	var next_id := String(choice.get("next", ""))
	if next_id != "":
		_enter_node(next_id)
	else:
		_end_dialog()

func _apply_event(event_value) -> void:
	if event_value is String:
		dialog_event_emitted.emit(event_value, {})
		return
	if not (event_value is Dictionary):
		return
	var event: Dictionary = event_value as Dictionary
	var event_type: String = String(event.get("type", ""))
	if event_type == "":
		return
	if event_type == "accept_job":
		var job_path: String = String(event.get("job_path", ""))
		var job: Job = _load_job(job_path)
		if job:
			dialog_event_emitted.emit(event_type, {"job_path": job_path})
			job_accepted.emit(job)
		return
	if event_type == "complete_job":
		var job_id: String = String(event.get("job_id", ""))
		if job_id != "":
			var player_state: PlayerStateComponent = _get_player_state()
			if player_state:
				var job: Job = _find_job_by_id(player_state.active_jobs, job_id)
				if job:
					job.status = "complete"
					player_state.active_jobs.erase(job)
					player_state.completed_jobs.append(job)
					dialog_event_emitted.emit(event_type, {"job_id": job_id})
					job_completed.emit(job)
		return
	if event_type == "close_dialog":
		_end_dialog()
		return
	dialog_event_emitted.emit(event_type, event)

func _load_job(path: String) -> Job:
	var player_state: PlayerStateComponent = _get_player_state()
	if player_state == null:
		return null
	var resource: Job = load(path) as Job
	if resource == null:
		return null
	var existing_id := resource.id
	for job in player_state.active_jobs:
		if job is Job and job.id == existing_id:
			return null
	for job in player_state.completed_jobs:
		if job is Job and job.id == existing_id:
			return null
	var job: Job = resource.duplicate(true) as Job
	if job == null:
		return null
	job.status = "active"
	player_state.active_jobs.append(job)
	return job

func _find_node(tree: DialogTree, node_id: String) -> Dictionary:
	if tree == null:
		return {}
	for node in tree.nodes:
		if node is Dictionary and node.get("id", "") == node_id:
			return node
	return {}

func _find_job_by_id(jobs: Array, job_id: String) -> Job:
	for job in jobs:
		if job is Job and job.id == job_id:
			return job
	return null

func _get_player_state() -> PlayerStateComponent:
	var nodes: Array[Node] = get_tree().root.find_children("", "ComponentHost", true, false)
	for node in nodes:
		var host: ComponentHost = node as ComponentHost
		if host and host.has_component(&"PlayerStateComponent"):
			return host.get_component(&"PlayerStateComponent") as PlayerStateComponent
	return null

func _find_component_host(node: Node) -> ComponentHost:
	var current: Node = node
	while current:
		if current is ComponentHost:
			return current as ComponentHost
		current = current.get_parent()
	return null

func _end_dialog() -> void:
	active_tree = null
	active_node = {}
	active_npc = null
	dialog_ended.emit()
