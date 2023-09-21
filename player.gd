extends CharacterBody3D

signal hit
# Player movement speed
@export var speed = 14
# Downward acceleration while in midair
@export var fall_acceleration = 75
# Vertical impulse applied to the character upon jumping in meters per second.
@export var jump_impulse = 20
# Ray-cast length
@export var ray_length = 10.0

# Vertical impulse applied to the character upon bouncing over a mob in
# meters per second.
@export var bounce_impulse = 16

# Boost status
var boosting = {
	true:1.5,
	false:1
}

func _physics_process(delta):
	# Calculate the movement direction based on analog stick input
	
	var direction = Vector3(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		0,
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	)
	
	var look_direction = Vector3(
		Input.get_action_strength("look_right") - Input.get_action_strength("look_left"),
		0,
		Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	)

	# Normalize the direction vector to ensure consistent speed in all directions
	direction = direction.normalized()
	

	# Update the character's orientation
	if direction != Vector3.ZERO:
		$Pivot.look_at(position + direction, Vector3.UP)
		$AnimationPlayer.speed_scale = 4 * boosting[Input.is_action_pressed("boost")]
	else:
		$AnimationPlayer.speed_scale = 1
	
	if look_direction != Vector3.ZERO:
		$GunPivot.look_at(position + look_direction, Vector3.UP)
	else:
		if direction != Vector3.ZERO:
			$GunPivot.look_at(position + direction, Vector3.UP)
	
	# Calculate the target velocity based on the normalized direction and speed
	var target_velocity = direction * speed * boosting[Input.is_action_pressed("boost")]

	# Vertical Velocity
	if not is_on_floor():
		# Apply downward acceleration (gravity) while in midair
		target_velocity.y -= fall_acceleration * delta

	# Jumping.
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		target_velocity.y = jump_impulse


	for index in range(get_slide_collision_count()):
		# We get one of the collisions with the player
		var collision = get_slide_collision(index)

		# If the collision is with ground
		if (collision.get_collider() == null):
			continue

		# If the collider is with a mob
		if collision.get_collider().is_in_group("mob"):
			var mob = collision.get_collider()
			# we check that we are hitting it from above.
			if Vector3.UP.dot(collision.get_normal()) > 0.1:
				# If so, we squash it and bounce.
				mob.squash()
				target_velocity.y = bounce_impulse
	
	# Gun Shooting
	if Input.is_action_just_pressed("shoot"):
		$Gunshot.play()
		$GunPivot/Gun/Smoke.emitting = true
		$GunAnimator.play("shoot")
		# Check if the ray-cast hit something
		if $GunPivot/RaycastCast.is_colliding():
			# Check if the ray-cast hit a mob
			if $GunPivot/RaycastCast.get_collider().is_in_group("mob"):
				# Handle hitting a mob (you can define your own logic here)
				var mob = $GunPivot/RaycastCast.get_collider()
				mob.squash()  # Example: Deal 10 damage to the mob


	# Set the character's velocity
	velocity = target_velocity
	
	# Move the character using move_and_slide with no arguments
	move_and_slide()
	$Pivot.rotation.x = PI / 6 * velocity.y / jump_impulse

func die():
	hit.emit()
	queue_free()


func _on_mob_detector_body_entered(body):
	die()
