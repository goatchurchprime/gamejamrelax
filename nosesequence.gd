extends Node3D

@onready var headcontroller = XRHelpers.get_xr_camera(get_node("../XROrigin3D"))

var nosespotI = 0
func _ready():
	var nosespot0 = $Spot0
	for i in range(1, 40):
		var nosespoti = nosespot0.duplicate()
		nosespoti.name = "Spot%d" % i
		add_child(nosespoti)
		

var ppcount = 0
func _physics_process(delta):
	ppcount += 1
	if (ppcount % 2) == 1:
		get_child(nosespotI).transform = headcontroller.get_node("NosePointer").global_transform
		nosespotI = (nosespotI + 1) % get_child_count()
