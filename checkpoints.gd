extends Node3D

func _ready() -> void:
	for checkpoint in get_children():
		if checkpoint is Area3D:
			checkpoint.body_entered.connect(_on_checkpoint_entered.bind(checkpoint))

func _on_checkpoint_entered(Body : Node3D, checkpoint : Area3D) -> void:
	if not Body.is_in_group("Player"):
		return
	
	if not Body.current_checkpoint == checkpoint:
		Body.current_checkpoint = checkpoint
