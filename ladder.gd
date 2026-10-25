extends MeshInstance3D

@onready var area = $Area3D
@export_enum("W/S", "A/D", "D/A") var climbControls = 0

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("start_climbing") and body.activeRing == false:
		body.start_climbing(self)

func _on_body_exited(body: Node3D) -> void:
	if body.has_method("stop_climbing"):
		body.stop_climbing(self)
