extends Control

@onready var job_title_label: Label = $JobTitleLabel
@onready var objectives_container: VBoxContainer = $Objectives
@onready var objective_template: Label = $Objectives/ObjectiveTemplate

func _ready() -> void:
	objective_template.visible = false
	_refresh()
	var dialog: DialogSystemRuntime = get_node_or_null("/root/DialogSystem") as DialogSystemRuntime
	if dialog:
		dialog.job_accepted.connect(_on_job_event)
		dialog.job_completed.connect(_on_job_event)
	var objectives: ObjectiveSystemRuntime = get_node_or_null("/root/ObjectiveSystem") as ObjectiveSystemRuntime
	if objectives:
		objectives.objective_completed.connect(_on_objective_changed)
		objectives.job_status_changed.connect(_on_job_status_changed)

func _on_job_event(_job: Job) -> void:
	_refresh()

func _on_objective_changed(_job: Job, _objective: Objective) -> void:
	_refresh()

func _on_job_status_changed(_job: Job, _status: String) -> void:
	_refresh()

func _refresh() -> void:
	var player_state: PlayerStateComponent = _get_player_state()
	if player_state == null or player_state.active_jobs.is_empty():
		hide()
		return
	show()
	var job: Job = player_state.active_jobs[0] as Job
	if job == null:
		hide()
		return
	var status: String = job.status
	job_title_label.text = "Job: %s (%s)" % [job.title, status]
	_clear_objectives()
	for objective in job.objective_instances:
		if objective is Objective:
			var label: Label = objective_template.duplicate() as Label
			label.visible = true
			var completion: String = String(job.objective_statuses.get(objective.id, "active"))
			var prefix := "[ ]"
			if completion == "complete":
				prefix = "[x]"
			label.text = "%s %s" % [prefix, objective.title]
			objectives_container.add_child(label)

func _clear_objectives() -> void:
	for child in objectives_container.get_children():
		if child != objective_template:
			child.queue_free()

func _get_player_state() -> PlayerStateComponent:
	var nodes: Array[Node] = get_tree().root.find_children("", "ComponentHost", true, false)
	for node in nodes:
		var host: ComponentHost = node as ComponentHost
		if host and host.has_component(&"PlayerStateComponent"):
			return host.get_component(&"PlayerStateComponent") as PlayerStateComponent
	return null
