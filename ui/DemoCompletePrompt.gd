extends Control

@export var demo_job_id: String = "chip_delivery"

@onready var return_button: Button = $Panel/Content/Buttons/ReturnButton
@onready var quit_button: Button = $Panel/Content/Buttons/QuitButton

func _ready() -> void:
	hide()
	return_button.pressed.connect(_on_return_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	var dialog: DialogSystemRuntime = get_node_or_null("/root/DialogSystem") as DialogSystemRuntime
	if dialog:
		dialog.job_completed.connect(_on_job_completed)

func _on_job_completed(job: Job) -> void:
	if job.id == demo_job_id:
		show()

func _on_return_pressed() -> void:
	hide()
	var state: GameStateSystemRuntime = get_node_or_null("/root/GameStateSystem") as GameStateSystemRuntime
	if state:
		state.return_to_title()

func _on_quit_pressed() -> void:
	get_tree().quit()
