
extends Node3D

@onready var actionCamera = $ActionCamera
@onready var activationPillar = $ActivationPillar
var playerCamera = null

@export var leverSound : AudioStreamPlayer
@export var winSound : AudioStreamPlayer
@export var rockSound : AudioStreamPlayer

var activatedLevers = []
var totalLevers = 0
var originalPillarPosition = Vector3.ZERO
var originalCameraSize = 5.0

func _ready() -> void:
	actionCamera.current = false

	originalPillarPosition = activationPillar.position
	activationPillar.position.y -= 10.0
	originalCameraSize = actionCamera.size

	for lever in get_children():
		if lever == actionCamera or lever == activationPillar:
			continue

		var activationArea = lever.get_node_or_null("ActivationArea")

		if activationArea:
			totalLevers += 1
			activationArea.body_entered.connect(_on_lever_activated.bind(lever))

func _on_lever_activated(body: Node3D, leverNode: Node3D) -> void:
	if not body.is_in_group("Player"):
		return
	else:
		if not playerCamera: playerCamera = body.get_node("Camera3D")

	if leverNode in activatedLevers:
		return

	activatedLevers.append(leverNode)
	
	leverSound.play()

	var leverScale = leverNode.scale
	var tween = create_tween().set_parallel(true)

	tween.tween_property(
		leverNode.get_node("Lever"),
		"rotation_degrees:x",
		leverNode.get_node("Lever").rotation_degrees.x - 90.0,
		0.5
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		leverNode,
		"scale",
		leverScale * 1.05,
		0.05
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.set_parallel(false)

	tween.tween_property(
		leverNode,
		"scale",
		leverScale,
		0.05
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	if activatedLevers.size() == totalLevers:
		await tween.finished
		await _activate_pillar()

func _activate_pillar() -> void:
	actionCamera.make_current()
	
	rockSound.play()
	winSound.play()

	var tween = create_tween().set_parallel(true)

	tween.tween_property(
		activationPillar,
		"position",
		originalPillarPosition,
		2.0
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		actionCamera,
		"size",
		originalCameraSize * 0.9,
		2.0
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	await get_tree().create_timer(1.0).timeout

	if playerCamera != actionCamera:
		playerCamera.make_current()
