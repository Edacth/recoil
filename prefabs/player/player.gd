extends CharacterBody3D
class_name Player

#@export_subgroup("Properties")
@export var movement_speed = 5

@export_subgroup("Weapons")
@export var weapons: Array[Weapon] = []

var weapon: Weapon
var weapon_index := 0

var mouse_sensitivity = 700
var mouse_captured := true

var movement_velocity: Vector3
var rotation_target: Vector3

var input: Vector3
var input_mouse: Vector2

var health:int = 100

var previously_floored := false

var container_offset = Vector3(1.2, -1.1, -2.75)

var tween:Tween

signal health_updated

@onready var camera = $Head/Camera
@onready var raycast = $Head/Camera/RayCast
@onready var muzzle = $Head/Camera/SubViewportContainer/SubViewport/CameraItem/Muzzle
@onready var container = $Head/Camera/SubViewportContainer/SubViewport/CameraItem/Container
@onready var sound_footsteps = $SoundFootsteps
@onready var blaster_cooldown = $Cooldown
@onready var gravity_influence:= $GravityInfluence as GravityInfluence
@onready var knockback_influence:= $KnockbackInfluence as KnockbackInfluence
@onready var drag_cloak := $DragCloak as DragCloak

@export var crosshair:TextureRect


func _ready():
	gravity_influence.init(self, drag_cloak)
	knockback_influence.init(drag_cloak)
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED	
	initiate_change_weapon(weapon_index)


func _physics_process(delta):
	handle_controls(delta)
	handle_gravity(delta)
	handle_knockback(delta)
	
	# Movement
	var applied_velocity: Vector3
	movement_velocity = transform.basis * movement_velocity # Move forward
	var knockback_velocity = knockback_influence.get_influence()
	
#	applied_velocity = velocity.lerp(movement_velocity + knockback_velocity, delta * 10)
	applied_velocity = movement_velocity + knockback_velocity
	
	var gravity_velocity = gravity_influence.get_influence()
	
	
	applied_velocity.y += gravity_velocity
#	applied_velocity += knockback_velocity
	velocity = applied_velocity
	move_and_slide()
	
	# Rotation
	camera.rotation.z = lerp_angle(camera.rotation.z, -input_mouse.x * 25 * delta, delta * 5)	
	camera.rotation.x = lerp_angle(camera.rotation.x, rotation_target.x, delta * 25)
	rotation.y = lerp_angle(rotation.y, rotation_target.y, delta * 25)
	container.position = lerp(container.position, container_offset - (applied_velocity / 30), delta * 10)
	
	# Movement sound
	sound_footsteps.stream_paused = true
	if is_on_floor():
		if abs(velocity.x) > 1 or abs(velocity.z) > 1:
			sound_footsteps.stream_paused = false
	
	# Landing after jump or falling
	camera.position.y = lerp(camera.position.y, 0.0, delta * 5)
	
	if is_on_floor() and gravity_influence.get_influence() < 1 and !previously_floored: # Landed
		Audio.play("sounds/land.ogg")
		camera.position.y = -0.1
	previously_floored = is_on_floor()
	
	# Falling/respawning
	if position.y < -10:
		get_tree().reload_current_scene()


func handle_controls(_delta):
	# Mouse capture
	if Input.is_action_just_pressed("mouse_capture"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		mouse_captured = true
	
	if Input.is_action_just_pressed("mouse_capture_exit"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mouse_captured = false
		
		input_mouse = Vector2.ZERO
	
	# Movement
	input.x = Input.get_axis("move_left", "move_right")
	input.z = Input.get_axis("move_forward", "move_back")
	
	movement_velocity = input.normalized() * movement_speed
	
	# Rotation
	var rotation_input := Vector3.ZERO
	
	rotation_input.y = Input.get_axis("camera_left", "camera_right")
	rotation_input.x = Input.get_axis("camera_up", "camera_down") / 2
	
	rotation_target -= rotation_input.limit_length(1.0) * 5
	rotation_target.x = clamp(rotation_target.x, deg_to_rad(-90), deg_to_rad(90))
	
	if Input.is_action_pressed("shoot"):
		action_shoot(_delta)
	
	if Input.is_action_just_pressed("jump"):
		gravity_influence.jump()
		
	# Weapon switching
	action_weapon_toggle()
	
	if Input.is_action_just_pressed("drag_cloak"):
		drag_cloak.activate()
		
	if Input.is_action_just_released("drag_cloak"):
		drag_cloak.deactivate()


func action_shoot(delta):
	if !blaster_cooldown.is_stopped(): return # Cooldown for shooting
	
	if weapon:
		Audio.play(weapon.sound_shoot)
	
	container.position.z += 0.25 # Knockback of weapon visual
	var test: Vector3 = camera.global_transform.basis.z
	knockback_influence.add_influence(test, weapon.knockback)

	camera.rotation.x += 0.025 # Knockback of camera
	
	# Set muzzle flash position, play animation
	
	muzzle.play("default")
	
	muzzle.rotation_degrees.z = randf_range(-45, 45)
	muzzle.scale = Vector3.ONE * randf_range(0.40, 0.75)
	muzzle.position = container.position - weapon.muzzle_position
	
	blaster_cooldown.start(weapon.cooldown)
	
	# Shoot the weapon, amount based on shot count
	
	for n in weapon.shot_count:
	
		raycast.target_position.x = randf_range(-weapon.spread, weapon.spread)
		raycast.target_position.y = randf_range(-weapon.spread, weapon.spread)
		
		raycast.force_raycast_update()
		
		if !raycast.is_colliding(): continue # Don't create impact when raycast didn't hit
		
		var collider = raycast.get_collider()
		
		# Hitting an enemy
		
		if collider.has_method("damage"):
			collider.damage(weapon.damage)
		
		# Creating an impact animation
		
		var impact = preload("res://objects/impact.tscn")
		var impact_instance = impact.instantiate()
		
		impact_instance.play("shot")
		
		get_tree().root.add_child(impact_instance)
		
		impact_instance.position = raycast.get_collision_point() + (raycast.get_collision_normal() / 10)
		impact_instance.look_at(camera.global_transform.origin, Vector3.UP, true) 


func action_jump():
	gravity_influence.jump()


func handle_gravity(delta):
	gravity_influence.handle_gravity(delta)
	


func handle_knockback(delta):
	knockback_influence.handle_influence(delta)


func action_weapon_toggle():
	
	if Input.is_action_just_pressed("weapon_toggle"):
		
		weapon_index = wrap(weapon_index + 1, 0, weapons.size())
		initiate_change_weapon(weapon_index)
		
		Audio.play("sounds/weapon_change.ogg")


func initiate_change_weapon(index):
	# Initiates the weapon changing animation (tween)
	weapon_index = index
	
	tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT_IN)
	tween.tween_property(container, "position", container_offset - Vector3(0, 1, 0), 0.1)
	tween.tween_callback(change_weapon) # Changes the model

# Switches the weapon model (off-screen)

func change_weapon():
	
	weapon = weapons[weapon_index]

	# Step 1. Remove previous weapon model(s) from container
	
	for n in container.get_children():
		container.remove_child(n)
	
	# Step 2. Place new weapon model in container
	
	var weapon_model = weapon.model.instantiate()
	container.add_child(weapon_model)
	
	weapon_model.position = weapon.position
	weapon_model.rotation_degrees = weapon.rotation
	
	# Step 3. Set model to only render on layer 2 (the weapon camera)
	
	for child in weapon_model.find_children("*", "MeshInstance3D"):
		child.layers = 2
		
	# Set weapon data
	
	raycast.target_position = Vector3(0, 0, -1) * weapon.max_distance
	crosshair.texture = weapon.crosshair


func _input(event):
	# Mouse movement
	if event is InputEventMouseMotion and mouse_captured:
		
		input_mouse = event.relative / mouse_sensitivity
		
		rotation_target.y -= event.relative.x / mouse_sensitivity
		rotation_target.x -= event.relative.y / mouse_sensitivity


func damage(amount):
	
	health -= amount
	health_updated.emit(health) # Update health on HUD
	
	if health < 0:
		get_tree().reload_current_scene() # Reset when out of health
