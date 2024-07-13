extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(false)


# Last ditch attempt as blendshape animations do not work
var t = 0
func _process(delta):
	t += delta
	var s = sin(t*2*PI/2)
	var s1 = pow(abs(s), 0.85)*sign(s)
	$koi_01/unit_conversion_scaling/Root/Paint_001.set_blend_shape_value(1, 0.5+s1)
	#print($koi_01/unit_conversion_scaling/Root/Paint_001.find_blend_shape_by_name("frame_0001"))

func triggerkoi():
	set_process(true)
	visible = true
	$AnimationPlayer.play("koiswim")
	await $AnimationPlayer.animation_finished
	set_process(false)
	visible = false
	
