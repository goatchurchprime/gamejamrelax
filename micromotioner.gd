extends Node3D

@onready var headcontroller = XRHelpers.get_xr_camera(self)
@onready var leftcontroller = XRHelpers.get_left_controller(self)
@onready var rightcontroller = XRHelpers.get_right_controller(self)


# butterworth filtering code (useful to apply to random noise sensors, like CO2sensor)
class ABfilter:
	var b = [ ]
	var a = [ ]
	var xybuff = [ ]
	var xybuffpos = 0
	func _init(lb, la):
		b = lb
		a = la
		assert (len(b) == len(a))

	func addfiltvalue(x):
		var n = len(b)
		if len(xybuff) == 0:
			xybuff.resize(n*2)
			xybuff.fill(x)
		xybuff[xybuffpos] = x 
		var j = xybuffpos 
		var y = 0
		for i in range(n):
			if i == 0:
				y = xybuff[j]*b[i] 
			else:
				y += xybuff[j]*b[i] 
				y -= xybuff[j+n]*a[i] 
			j = j-1 if j!=0 else n-1
		if a[0] != 1:
			y /= a[0]
		xybuff[xybuffpos+n] = y 
		xybuffpos = xybuffpos+1 if xybuffpos!=n-1 else 0
		var Dj = (n-1 if (xybuffpos == 0) else xybuffpos-1)
		assert (xybuff[Dj+n] == y)
		return y 

# b, a = scipy.signal.butter(3, 1.0/8, 'lp', fs=20, output='ba')
#var butterworthfilter = ABfilter.new([7.28117248e-06, 2.18435174e-05, 2.18435174e-05, 7.28117248e-06 ], [ 1.        , -2.92146522,  2.84598406, -0.92446058 ])
# b, a = signal.butter(3, 1.0/16, 'lp', fs=20, output='ba')
var butterworthfilter = ABfilter.new([9.27927517e-07, 2.78378255e-06, 2.78378255e-06, 9.27927517e-07] , [ 1.        , -2.96073072,  2.9222287 , -0.96149055])

var nosespotI = 0
func _ready():
	$CentreDisplacer/Headpos/Nose.transform = headcontroller.get_node("Nose").transform
	$CentreDisplacer.transform*$CentreDisplacer/Headpos.transform*$CentreDisplacer/Headpos/Nose.transform.origin
	var nosespot0 = $NoseTrack/Spot0
	for i in range(1, 40):
		var nosespoti = nosespot0.duplicate()
		nosespoti.name = "Spot%d" % i
		$NoseTrack.add_child(nosespoti)
		
func _physics_process(delta):
	$NoseTrack.get_child(nosespotI).transform = global_transform.inverse()*$CentreDisplacer/Headpos/Nose.global_transform
	nosespotI = (nosespotI + 1) % $NoseTrack.get_child_count()
	
func _process(delta):
	$CentreDisplacer/Headpos.transform = headcontroller.transform
	#A*B = A.basis*B.basis, A.origin + A.basis*B.origin
	var nosepos = $CentreDisplacer/Headpos.transform*$CentreDisplacer/Headpos/Nose.transform.origin
	var filtnose = butterworthfilter.addfiltvalue(nosepos)
	$CentreDisplacer/noseball.transform.origin = nosepos
	$CentreDisplacer.transform.origin = -filtnose
	$CentreDisplacer/Lefthandpos.transform = leftcontroller.transform
	$CentreDisplacer/Righthandpos.transform = rightcontroller.transform
	
