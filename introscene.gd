extends Node3D


@onready var monkeytopmaterial = load("res://assets/monkeyshadertop.tres")

func _ready():
	for b in get_node("MonkeyOrb/Sphere/Monkey_Rigged--Animated_01a/Armature/Skeleton3D").get_children():
		if b.get_child_count() == 1:
			b.get_child(0).set_surface_override_material(0, monkeytopmaterial)
			b.get_child(0).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
