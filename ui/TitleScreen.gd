extends Control

@export var scenario_name: String = "Chip Delivery"
@export var scenario_path: String = "res://scenarios/chip_delivery/scenario.json"
@export var scenario_description: String = "Courier a tagged shard across the block."

@onready var scenario_list: ItemList = $ScenarioList
@onready var details_label: Label = $DetailsLabel
@onready var start_button: Button = $StartButton

func _ready() -> void:
	if scenario_list.item_count == 0:
		scenario_list.add_item(scenario_name)
		scenario_list.set_item_metadata(0, scenario_path)
	scenario_list.select(0)
	_update_details()
	scenario_list.item_selected.connect(_on_item_selected)
	start_button.pressed.connect(_on_start_pressed)

func _on_item_selected(index: int) -> void:
	scenario_list.select(index)
	_update_details()

func _update_details() -> void:
	var selection: PackedInt32Array = scenario_list.get_selected_items()
	if selection.is_empty():
		details_label.text = ""
		return
	details_label.text = "%s\n%s" % [scenario_name, scenario_description]

func _on_start_pressed() -> void:
	var selection: PackedInt32Array = scenario_list.get_selected_items()
	if selection.is_empty():
		return
	var path: String = String(scenario_list.get_item_metadata(selection[0]))
	var state: GameStateSystemRuntime = get_node_or_null("/root/GameStateSystem") as GameStateSystemRuntime
	if state:
		state.load_scenario(path)
