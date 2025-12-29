extends Control

@export var toast_duration: float = 2.0

@onready var speaker_label: Label = $SpeakerLabel
@onready var body_label: Label = $BodyLabel
@onready var choices_container: VBoxContainer = $Choices
@onready var job_toast: Label = $JobToast

var active_tree: DialogTree = null

func _ready() -> void:
	hide()
	job_toast.visible = false
	var dialog: DialogSystemRuntime = get_node_or_null("/root/DialogSystem") as DialogSystemRuntime
	if dialog:
		dialog.dialog_started.connect(_on_dialog_started)
		dialog.dialog_node_reached.connect(_on_dialog_node_reached)
		dialog.dialog_ended.connect(_on_dialog_ended)
		dialog.job_accepted.connect(_on_job_accepted)
		dialog.job_completed.connect(_on_job_completed)

func _on_dialog_started(tree: DialogTree, _npc: Node3D) -> void:
	active_tree = tree
	show()

func _on_dialog_node_reached(node_id: String) -> void:
	var node: Dictionary = _find_node(node_id)
	if node.is_empty():
		return
	speaker_label.text = String(node.get("speaker", ""))
	body_label.text = String(node.get("text", ""))
	_render_choices(node.get("choices", []))

func _on_dialog_ended() -> void:
	hide()
	_clear_choices()
	active_tree = null

func _on_job_accepted(job: Job) -> void:
	_show_toast("Job Accepted: %s" % job.title)

func _on_job_completed(job: Job) -> void:
	_show_toast("Job Complete: %s" % job.title)

func _render_choices(choice_data: Variant) -> void:
	_clear_choices()
	if not (choice_data is Array):
		return
	var choices: Array = choice_data
	for index in range(choices.size()):
		var choice: Variant = choices[index]
		if choice is Dictionary:
			var label := Label.new()
			label.text = "%d) %s" % [index + 1, String(choice.get("label", ""))]
			choices_container.add_child(label)

func _clear_choices() -> void:
	for child in choices_container.get_children():
		child.queue_free()

func _find_node(node_id: String) -> Dictionary:
	if active_tree == null:
		return {}
	for node in active_tree.nodes:
		if node is Dictionary and node.get("id", "") == node_id:
			return node
	return {}

func _show_toast(message: String) -> void:
	job_toast.text = message
	job_toast.visible = true
	var timer: SceneTreeTimer = get_tree().create_timer(toast_duration)
	timer.timeout.connect(_hide_toast)

func _hide_toast() -> void:
	job_toast.visible = false
