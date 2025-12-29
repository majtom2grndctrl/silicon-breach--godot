extends Resource
class_name Job

@export var id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var giver: String = ""
@export var reward: String = ""
@export var objectives: Array = []
@export var status: String = "available"

var objective_instances: Array = []
var objective_statuses: Dictionary = {}
