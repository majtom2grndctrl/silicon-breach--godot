extends Node
class_name ComponentHost

signal component_added(component: Resource)
signal component_removed(component_type: StringName)

@export var components_list: Array[Resource] = []
var components: Dictionary = {}

func _ready() -> void:
	for component in components_list:
		_register_component(component)

func has_component(component_type: StringName) -> bool:
	return components.has(component_type)

func get_component(component_type: StringName) -> Resource:
	return components.get(component_type)

func add_component(component: Resource) -> void:
	if component == null:
		return
	components_list.append(component)
	_register_component(component)

func remove_component(component_type: StringName) -> void:
	if not components.has(component_type):
		return
	components.erase(component_type)
	component_removed.emit(component_type)

func _register_component(component: Resource) -> void:
	var key := _get_component_key(component)
	if key == &"":
		return
	components[key] = component
	component_added.emit(component)

func _get_component_key(component: Resource) -> StringName:
	var script_class := component.get_class()
	if script_class != "":
		return StringName(script_class)
	var script: Script = component.get_script()
	if script and script.resource_path != "":
		return StringName(script.resource_path)
	return &""
