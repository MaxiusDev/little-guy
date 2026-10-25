
extends CharacterBody3D

@export_category("Movement 🏃‍♀️‍➡️")
@export var speed = 2.5
@export var jumpVelocity = 2.0
@export var airControl = 0.075

@export var normal_texture: Texture2D
@export var blink_texture: Texture2D

@onready var headCheck = $HeadCheck

@export var popSound : AudioStreamPlayer
@export var popSound2 : AudioStreamPlayer
@export var jumpSound : AudioStreamPlayer
@export var errorSound : AudioStreamPlayer
@export var stepsSound : AudioStreamPlayer

var current_checkpoint = null

@onready var character = $Armature
@onready var mesh = $Armature/Skeleton3D/Character
@onready var camera = $Camera3D
@onready var shadowRay = $ShadowRaycast
@onready var shadow = $Shadow
@onready var animationPlayer = $"AnimationPlayer"
@onready var bigCollision = $"BigCollision"
@onready var smallCollision = $"SmallCollision"

@export var ring: StaticBody3D
@export var ringCloud: Sprite3D

var ringScale = Vector3.ONE
var activeRing = false
var ringOnCooldown = false
var playerClone = null
var shadowClone = null
var originalScale = Vector3.ONE
var offset = Vector3(0, 0.15, 0)

signal clone_hit_area

var cloneVelocity = Vector3.ZERO
var cloneGravity = 9.8
var cloneRay: RayCast3D
var cloneFloorOffset = 0.6
var clonePlatform: Node3D = null
var clonePlatformPreviousPosition = Vector3.ZERO

@export_category("Ladder 🪜")
@export var ladderSpeed = 1.0
@export var ladderSnapSpeed = 5.0
@export var ladderRotationSpeed = 5.0
@export var ladderDistance = -4.0
var currentLadder: Node3D = null
var ladderTargetPosition = Vector3.ZERO
var ladderTargetRotation = 0.0

@export_category("Tilt ↗️")
@export var tiltAmount = 3.0
@export var tiltSpeed = 4.0
var originalCharacterRotation = Vector3.ZERO

@export_category("Camera 🎥")
@export var cameraSmoothness = 5.0
var cameraOffset = Vector3.ZERO

func _on_clone_hit_area() -> void:
	if activeRing and not ringOnCooldown:
		Input.action_press("ring")
		Input.action_release("ring")

func random_blink():
	while true:
		await get_tree().create_timer(randf_range(2.0, 6.0)).timeout
		await blink()

func blink():
	var material = mesh.get_active_material(0).duplicate()
	mesh.set_surface_override_material(0, material)
	material.albedo_texture = blink_texture

	await get_tree().create_timer(0.15).timeout

	material.albedo_texture = normal_texture

func _ready() -> void:
	clone_hit_area.connect(_on_clone_hit_area)
	random_blink()
	cameraOffset = camera.position
	camera.set_as_top_level(true)

	ringScale = ring.scale
	originalScale = character.scale
	originalCharacterRotation = character.rotation

	floor_snap_length = 1.0
	floor_constant_speed = true


func _physics_process(delta: float) -> void:
	if currentLadder != null:
		if not is_instance_valid(currentLadder):
			currentLadder = null
		else:
			process_ladder(delta)
			update_shadow(delta)
			update_camera(delta)
			return

	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if activeRing:
		ringCloud.visible = true
	else:
		ringCloud.visible = false

	if Input.is_action_just_pressed("jump") and is_on_floor():
		jumpSound.play()
		velocity.y = jumpVelocity

	if Input.is_action_just_pressed("ring"):
		if not activeRing and not ringOnCooldown:
			activeRing = true
			popSound.play()
			cloneVelocity = Vector3.ZERO
			clonePlatform = null

			ring.get_node("FloorCollision").disabled = false
			ring.get_node("WallCollision").disabled = false

			ring.global_position = global_position - Vector3(0, 0.3, 0)

			ring.scale = ringScale * 0.5
			var ringTween = create_tween()
			ringTween.tween_property(ring, "scale", ringScale, 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

			shadowClone = shadow.duplicate()
			get_parent().add_child(shadowClone)
			shadowClone.global_transform = shadow.global_transform

			playerClone = character.duplicate()
			get_parent().add_child(playerClone)
			playerClone.global_transform = character.global_transform
			playerClone.add_to_group("Clone")

			var cloneArea = Area3D.new()
			cloneArea.name = "CloneArea"
			playerClone.add_child(cloneArea)
			cloneArea.position = Vector3.ZERO
			cloneArea.collision_layer = 4
			cloneArea.collision_mask = 0

			var cloneCollision = CollisionShape3D.new()
			cloneCollision.name = "CollisionShape3D"
			cloneArea.add_child(cloneCollision)

			var cloneShape = CapsuleShape3D.new()
			cloneShape.radius = 0.3
			cloneShape.height = 1.2
			cloneCollision.shape = cloneShape

			cloneRay = RayCast3D.new()
			playerClone.add_child(cloneRay)
			playerClone.add_to_group("Clone")
			cloneRay.position = Vector3(0, -cloneFloorOffset, 0)
			cloneRay.target_position = Vector3(0, -3.0, 0)
			cloneRay.enabled = true
			cloneRay.add_exception(self)

			var cloneScale = playerClone.scale
			playerClone.scale = cloneScale * 0.01

			var cloneTween = create_tween()
			cloneTween.tween_property(playerClone, "scale", cloneScale, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

			mesh.get_active_material(0).albedo_color = Color("DBD3D8")
			mesh.set_surface_override_material(0, mesh.get_active_material(0).duplicate())
			var material = mesh.get_active_material(0)
			material.albedo_color = Color("ffffffff")

			global_position.y += offset.y
			character.scale = originalScale * 0.4

			bigCollision.disabled = true
			smallCollision.disabled = false
			speed += 0.5

		elif activeRing and not ringOnCooldown:
			headCheck.force_shapecast_update()

			if headCheck.is_colliding():
				errorSound.play()
				return
				
			ringOnCooldown = true
			popSound2.play()

			ring.get_node("FloorCollision").disabled = true
			ring.get_node("WallCollision").disabled = true

			var ringTween = create_tween()
			ringTween.tween_property(ring, "scale", ringScale * 0.01, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

			if is_instance_valid(playerClone):
				var cloneTween = create_tween()
				cloneTween.tween_property(playerClone, "scale", playerClone.scale * 0.01, 0.125).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

			global_position.y += offset.y
			character.scale = originalScale

			activeRing = false
			clonePlatform = null

			var material = mesh.get_active_material(0)
			material.albedo_color = Color("ffffffff")

			bigCollision.disabled = false
			smallCollision.disabled = true
			speed -= 0.5

			await get_tree().create_timer(0.125).timeout

			if is_instance_valid(playerClone):
				playerClone.queue_free()

			if is_instance_valid(shadowClone):
				shadowClone.queue_free()

			playerClone = null
			shadowClone = null
			cloneRay = null

			ring.global_position = Vector3(0, -200, 0)
			ring.scale = ringScale

			ringOnCooldown = false

	var inputDirection = Input.get_vector("left", "right", "up", "down")
	var cameraBasis = camera.global_transform.basis
	var direction = cameraBasis.x * inputDirection.x + cameraBasis.z * inputDirection.y
	direction.y = 0
	direction = direction.normalized()

	if is_on_floor() and not direction.is_zero_approx():
		direction = direction.slide(get_floor_normal()).normalized()

	var movementControl = 1.0 if is_on_floor() else airControl
	var movementSpeed = speed if is_on_floor() else speed * 0.65
	var targetVelocity = direction * movementSpeed

	velocity.x = move_toward(velocity.x, targetVelocity.x, speed * movementControl)
	velocity.z = move_toward(velocity.z, targetVelocity.z, speed * movementControl)

	if direction:
		var targetRotation = atan2(direction.x, direction.z)
		character.rotation.y = lerp_angle(character.rotation.y, targetRotation, 10.0 * delta)

	var localDirection = character.global_basis.inverse() * direction
	var targetTilt = Vector3.ZERO

	if not direction.is_zero_approx():
		targetTilt.x = abs(localDirection.z) * deg_to_rad(tiltAmount / 3 if activeRing else tiltAmount)
		targetTilt.z = localDirection.x * deg_to_rad(tiltAmount / 3 if activeRing else tiltAmount)

	character.rotation.x = lerp_angle(character.rotation.x, originalCharacterRotation.x + targetTilt.x, tiltSpeed * delta)
	character.rotation.z = lerp_angle(character.rotation.z, originalCharacterRotation.z + targetTilt.z, tiltSpeed * delta)

	move_and_slide()

	if not is_on_floor():
		animationPlayer.play("Fall", 0.8, 2.0)
	elif direction:
		if activeRing:
			ringCloud.get_node("CPUParticles3D").emitting = true
			ringCloud.global_position.x = self.global_position.x
			ringCloud.global_position.z = self.global_position.z
			animationPlayer.play("Walk_2", 0.8, speed * 2.0)
		else:
			ringCloud.get_node("CPUParticles3D").emitting = false
			animationPlayer.play("Walk", 0.8, speed * 2.0)
	else:
		ringCloud.get_node("CPUParticles3D").emitting = false
		animationPlayer.play("Idle", 0.8, 2.0)

	if activeRing and is_instance_valid(playerClone) and is_instance_valid(cloneRay):
		cloneRay.force_raycast_update()

		if cloneRay.is_colliding():
			var cloneFloor = get_moving_platform(cloneRay.get_collider())

			if cloneFloor != null:
				if clonePlatform != cloneFloor:
					clonePlatform = cloneFloor
					clonePlatformPreviousPosition = cloneFloor.global_position
				else:
					var platformMovement = cloneFloor.global_position.y - clonePlatformPreviousPosition.y
					playerClone.global_position.y += platformMovement
					clonePlatformPreviousPosition = cloneFloor.global_position

				cloneVelocity.y = 0.0
			else:
				clonePlatform = null
				cloneVelocity.y = 0.0
		else:
			clonePlatform = null
			cloneVelocity.y -= cloneGravity * delta
			playerClone.global_position.y += cloneVelocity.y * delta

		ring.global_position.y = playerClone.global_position.y - 0.3

	update_shadow(delta)
	update_camera(delta)


func get_moving_platform(collider: Object) -> Node3D:
	var currentNode = collider as Node

	while currentNode != null:
		if currentNode.is_in_group("MovingPlatforms") and currentNode is Node3D:
			return currentNode as Node3D

		currentNode = currentNode.get_parent()

	return null


func update_camera(delta: float) -> void:
	var cameraTargetPosition = global_position + global_basis * cameraOffset

	camera.global_position = camera.global_position.lerp(
		cameraTargetPosition,
		1.0 - exp(-cameraSmoothness * delta)
	)


func start_climbing(ladder: Node3D) -> void:
	if currentLadder != null:
		return

	currentLadder = ladder
	velocity = Vector3.ZERO

	var ladderForward = ladder.global_basis.z
	ladderTargetPosition = ladder.global_position + ladderForward * ladderDistance
	ladderTargetRotation = atan2(-ladderForward.x, -ladderForward.z)


func stop_climbing(ladder: Node3D) -> void:
	if currentLadder == ladder:
		currentLadder = null
		velocity = Vector3.ZERO


func process_ladder(delta: float) -> void:
	velocity = Vector3.ZERO

	var ladderForward = -currentLadder.global_basis.z
	var targetPosition = currentLadder.global_position + ladderForward * ladderDistance

	global_position.x = move_toward(global_position.x, targetPosition.x, ladderSnapSpeed * delta)
	global_position.z = move_toward(global_position.z, targetPosition.z, ladderSnapSpeed * delta)

	character.rotation.x = lerp_angle(character.rotation.x, originalCharacterRotation.x, ladderRotationSpeed * delta)
	character.rotation.z = lerp_angle(character.rotation.z, originalCharacterRotation.z, ladderRotationSpeed * delta)
	character.rotation.y = lerp_angle(character.rotation.y, ladderTargetRotation, ladderRotationSpeed * delta)

	var climbDirection = 0.0

	if currentLadder.climbControls == 0:
		climbDirection = Input.get_axis("down", "up")
	elif currentLadder.climbControls == 1:
		climbDirection = Input.get_axis("left", "right")
	elif currentLadder.climbControls == 2:
		climbDirection = Input.get_axis("right", "left")

	global_position.y += climbDirection * ladderSpeed * delta

	var bottom = currentLadder.get_node_or_null("Bottom")
	var top = currentLadder.get_node_or_null("Top")

	if bottom != null and global_position.y <= bottom.global_position.y:
		global_position.y = bottom.global_position.y
		stepsSound.stop()
		stop_climbing(currentLadder)
	elif top != null and global_position.y >= top.global_position.y:
		global_position.y = top.global_position.y
		stepsSound.stop()
		stop_climbing(currentLadder)

	if currentLadder != null:
		if abs(climbDirection) > 0.01:
			if animationPlayer.current_animation != "Climb":
				animationPlayer.play("Climb", -1.0, 3.0)
				stepsSound.play()

			animationPlayer.speed_scale = sign(climbDirection)
			animationPlayer.seek(animationPlayer.current_animation_position, true)
		else:
			stepsSound.stop()
			animationPlayer.pause()


func update_shadow(delta: float) -> void:
	shadowRay.force_raycast_update()

	if shadowRay.is_colliding():
		var shadowPosition = shadowRay.get_collision_point()
		var shadowNormal = shadowRay.get_collision_normal()
		var shadowDistance = global_position.distance_to(shadowPosition)
		var shadowScale = clamp(1.0 - shadowDistance / 5.0 * 0.7, 0.3, 1.0)

		shadow.global_position = shadowPosition + shadowNormal * 0.0125

		var currentScale = shadow.global_basis.get_scale()
		var targetBasis = Basis.looking_at(shadowNormal, Vector3.FORWARD) * Basis.from_euler(Vector3(deg_to_rad(90), 0, 0))
		var targetRotation = shadow.global_basis.orthonormalized().get_rotation_quaternion().slerp(
			targetBasis.get_rotation_quaternion(),
			min(15.0 * delta, 1.0)
		)

		shadow.global_basis = Basis(targetRotation).scaled(currentScale)
		shadow.scale = shadow.scale.lerp(Vector3.ONE * shadowScale, 8.0 * delta) / (1.25 if activeRing else 1.0)
		shadow.visible = true
	else:
		shadow.visible = false
