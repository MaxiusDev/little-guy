extends Node3D

@export var speed = 0.25

@onready var platform = $Platform
@onready var start = $Start
@onready var end = $End

func _ready() -> void:
	platform.global_position = start.global_position
	move_platform()

func move_platform() -> void:
	var distance = start.global_position.distance_to(end.global_position)
	var duration = distance / speed

	var tween = create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_loops()

	tween.tween_property(platform, "global_position", end.global_position, duration).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(platform, "global_position", start.global_position, duration).set_trans(Tween.TRANS_LINEAR)
