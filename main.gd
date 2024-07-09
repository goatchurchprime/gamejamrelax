extends Node3D

var stillnessscore = 0.0
var prevheadtransform : Transform3D = Transform3D()
const eyenosevector = Vector3(0, -0.2, -0.2)

func _ready():
	$Monkey/AnimationPlayer.play("KeyAction")
	$MonkeyReflection/AnimationPlayer.play("KeyAction")

func _process(delta):
	if not $VoiceGraph/AudioStreamMicrophone.playing:
		$VoiceGraph/AudioStreamMicrophone.playing = true
	
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

	var nosepoint = $XROrigin3D/XRCamera3D/NosePointer.global_transform.origin
	var mat = $Monkey/Monkey_Breathe.get_surface_override_material(0)
	mat.set_shader_parameter("noselight", nosepoint)
	var matrefl = $MonkeyReflection/Monkey_Breathe.get_surface_override_material(0)
	nosepoint.y = -$XROrigin3D.transform.origin.y - nosepoint.y
	matrefl.set_shader_parameter("noselight", nosepoint)
	#mat.set_shader_parameter("noselight", Vector3(0,0.7,0.3))
