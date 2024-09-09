class_name PlayerController
extends CharacterBody3D

@onready var leash_packed_scene: PackedScene = preload("res://scenes/misc/leash/leash.tscn")

@export var shout_cooldown: float = 5 # Seconds
@export var speed: float = 4
## The player's speed is multiplied by this number to the power of the number of leashed_animals.
## This lets the player can leash as many animals as they want without completely stopping.
@export_range(0, 1) var speed_reduction_per_dragged_body: float = 0.85
## The minimum distance an animal needs to be from the player for it to be dragged while being leashed.
@export var min_drag_distance: float = 1
@export var lasso_range: float = 3

@onready var raycast: RayCast3D = %RayCast3D
@onready var leash_point: Node3D = %LeashPoint
@onready var shout_area: Area3D = %ShoutArea

## Can be null when not targetting any animal
var targeted_animal: Animal:
	set(value):
		if targeted_animal:
			targeted_animal.hide_lasso()
		targeted_animal = value
		if targeted_animal:
			targeted_animal.show_lasso()

var leashed_animals: Array[Animal] = []
var current_shout_cooldown: float = 0

func _ready() -> void:
	Globals.player = self

func _physics_process(_delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if direction.length() > 0:
		var raycast_direction: Vector2 = direction.normalized() * lasso_range
		raycast.target_position = Vector3(raycast_direction.x, 0, raycast_direction.y)
	
	# Handle targetting and leashing of animals
	var body: Area3D = raycast.get_collider()
	if body and body.owner is Animal and body.owner not in leashed_animals:
		targeted_animal = body.owner
		if Input.is_action_just_pressed("use_lasso"):
			leashed_animals.append(body.owner)
			var leash: Leash = leash_packed_scene.instantiate()
			leash_point.add_child(leash)
			leash.end_node = body.owner.leash_point
	else:
		targeted_animal = null
		
	var movement_vector: Vector2 = direction * (speed * pow(speed_reduction_per_dragged_body, leashed_animals.size()))
	velocity = Vector3(movement_vector.x, 0, movement_vector.y)
	move_and_slide()
	
	# Drag leashed animals
	for animal: Animal in leashed_animals:
		if global_position.distance_to(animal.global_position) > min_drag_distance:
			animal.velocity = (global_position - animal.global_position) * 0.7
			animal.move_and_slide()

func _process(delta: float):
	current_shout_cooldown += delta
	Globals.shout_energy_changed.emit(clampf(current_shout_cooldown / shout_cooldown, 0, 1))
	if Input.is_action_just_pressed("shout") and current_shout_cooldown >= shout_cooldown:
		var bodies = shout_area.get_overlapping_bodies()
		for body in bodies:
			if body is Animal:
				body.scare(global_position)
		current_shout_cooldown = 0
		print("Shouted")
	
