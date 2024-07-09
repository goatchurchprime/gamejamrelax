extends Node3D


@onready var headcontroller = XRHelpers.get_xr_camera(get_node("../XROrigin3D"))
@onready var leftcontroller = XRHelpers.get_left_controller(get_node("../XROrigin3D"))
@onready var rightcontroller = XRHelpers.get_right_controller(get_node("../XROrigin3D"))

func _ready():
	pass # Replace with function body.

var avgposition = null
var stillnessscore = 0.0
func _physics_process(delta):
	var handmid = (leftcontroller.global_transform.origin + rightcontroller.global_transform.origin)*0.5
	avgposition = handmid if avgposition == null else avgposition*0.9 + handmid*0.1
	if transform.origin.distance_to(avgposition) > 0.01:
		transform.origin = avgposition
		stillnessscore = 0.0
	else:
		stillnessscore += delta
	$HandPlant.mesh.height = stillnessscore*0.02
	$GPUParticles3D.amount_ratio = min(1.0, 0.3 + stillnessscore/50)
	$GPUParticles3D.transform.origin.y = $HandPlant.mesh.height*0.5
	$HandMidDebug.global_transform.origin = avgposition
