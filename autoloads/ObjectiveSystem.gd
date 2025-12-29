extends Node
class_name ObjectiveSystemRuntime

signal objective_completed(job: Job, objective: Objective)
signal job_status_changed(job: Job, status: String)

func _ready() -> void:
	var interaction: InteractionSystemRuntime = get_node_or_null("/root/InteractionSystem") as InteractionSystemRuntime
	if interaction:
		interaction.item_taken.connect(_on_item_taken)
		interaction.item_delivered.connect(_on_item_delivered)
	var dialog: DialogSystemRuntime = get_node_or_null("/root/DialogSystem") as DialogSystemRuntime
	if dialog:
		dialog.dialog_node_reached.connect(_on_dialog_node_reached)

func _on_item_taken(item_id: String) -> void:
	_mark_objectives_by_rule("item_in_inventory", {"item_path": item_id})

func _on_item_delivered(item_id: String, marker_id: String) -> void:
	_mark_objectives_by_rule("item_delivered", {"item_path": item_id, "marker_id": marker_id})

func _on_dialog_node_reached(node_id: String) -> void:
	_mark_objectives_by_rule("dialog_node_reached", {"node_id": node_id})

func _mark_objectives_by_rule(rule_type: String, payload: Dictionary) -> void:
	var player_state: PlayerStateComponent = _get_player_state()
	if player_state == null:
		return
	for job in player_state.active_jobs:
		if job is Job:
			_update_job_objectives(job as Job, rule_type, payload)

func _update_job_objectives(job: Job, rule_type: String, payload: Dictionary) -> void:
	if job.objective_instances.is_empty():
		var spawning: SpawningSystemRuntime = get_node_or_null("/root/SpawningSystem") as SpawningSystemRuntime
		if spawning:
			spawning.initialize_job(job)
	for objective in job.objective_instances:
		if objective == null:
			continue
		if job.objective_statuses.get(objective.id, "active") == "complete":
			continue
		if _objective_matches(objective, rule_type, payload):
			job.objective_statuses[objective.id] = "complete"
			objective_completed.emit(job, objective)
	_update_job_status(job)

func _objective_matches(objective: Objective, rule_type: String, payload: Dictionary) -> bool:
	for rule in objective.completion_rules:
		if rule is Dictionary and rule.get("type") == rule_type:
			if rule_type == "item_in_inventory":
				return rule.get("item_path", "") == payload.get("item_path", "")
			if rule_type == "item_delivered":
				return rule.get("item_path", "") == payload.get("item_path", "") and rule.get("marker_id", "") == payload.get("marker_id", "")
			if rule_type == "dialog_node_reached":
				return rule.get("node_id", "") == payload.get("node_id", "")
	return false

func _update_job_status(job: Job) -> void:
	if job.status == "complete":
		return
	for objective in job.objective_instances:
		if objective == null:
			continue
		if job.objective_statuses.get(objective.id, "active") != "complete":
			return
	job.status = "awaiting_turn_in"
	job_status_changed.emit(job, job.status)

func _get_player_state() -> PlayerStateComponent:
	var nodes: Array[Node] = get_tree().root.find_children("", "ComponentHost", true, false)
	for node in nodes:
		var host: ComponentHost = node as ComponentHost
		if host and host.has_component(&"PlayerStateComponent"):
			return host.get_component(&"PlayerStateComponent") as PlayerStateComponent
	return null
