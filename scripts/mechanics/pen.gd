extends Area3D
class_name PenArea

## Invisible Leash settings
@export var min_drag_distance: float = 2
## Invisible Leash settings
@export var pull_coefficient: float = 0.2

var penned_animals: Array[Animal] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	## When an animal touched the pen area, remove any leashes,
	## and attach an invisible leash to keep them inside the pen.
	body_entered.connect(func(body: Node3D):
		if body is Animal and body not in penned_animals:
			var animal: Animal = body
			penned_animals.append(animal)
			Leash.unleash(animal)
			var leash = Leash.create_leash(self, animal.leash_point)
			leash.min_drag_distance = min_drag_distance
			leash.pull_coefficient = pull_coefficient
			leash.make_invisible()
	)
