extends Node3D

var stillnessscore = 0.0
var prevheadtransform : Transform3D = Transform3D()
const eyenosevector = Vector3(0, -0.2, -0.2)



func _process(delta):
	
	var headtransform = $XROrigin3D/XRCamera3D.global_transform
	var vecoriginchange = prevheadtransform.origin - headtransform.origin
	var vecnosechange = prevheadtransform*eyenosevector - headtransform*eyenosevector
	var dvecoriginchange = vecoriginchange.length()/delta
	var dvecnosechange = vecnosechange.length()/delta
	#print(dvecnosechange, " ", dvecoriginchange)
	prevheadtransform = headtransform
	if dvecnosechange < 0.015 and dvecoriginchange < 0.015:
		stillnessscore += delta
	else:
		stillnessscore = stillnessscore*0.9
	$StillnessLabel3D/StillnessScore.text = "%.1f" % stillnessscore
