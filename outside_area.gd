extends Area3D

var IsRespawning: bool = false
@export var waterSound: AudioStreamPlayer
@onready var splash: Sprite3D = $Splash
var splashScale = Vector3.ONE
@export var player: CharacterBody3D

func _ready() -> void:
	splashScale = splash.scale
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _on_body_entered(hit: Node3D) -> void:
	if not hit.is_in_group("Player"):
		return

	respawn_player()

func _on_area_entered(hit: Area3D) -> void:
	if hit.name != "CloneArea":
		return
	player.clone_hit_area.emit()
	respawn_player()

func respawn_player() -> void:
	if IsRespawning:
		return

	IsRespawning = true
	waterSound.play()

	splash.global_position.x = player.global_position.x
	splash.global_position.z = player.global_position.z
	splash.scale = splashScale * 0.01
	splash.modulate.a = 1.0
	splash.visible = true

	var splashTween = create_tween().set_parallel(true)
	splashTween.tween_property(splash, "scale", splashScale, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	splashTween.tween_property(splash, "modulate:a", 0.0, 0.5)

	await get_tree().create_timer(0.1).timeout

	var checkpointCollision = player.current_checkpoint.get_node("Collision")
	player.global_position = checkpointCollision.global_position

	IsRespawning = false

	await splashTween.finished
	splash.scale = splashScale * 0.01
	splash.visible = false
