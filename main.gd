extends Node3D

var stillnessscore = 0.0
var prevheadtransform : Transform3D = Transform3D()
const eyenosevector = Vector3(0, -0.2, -0.2)

func set_fade(p_value : float):
	XRToolsFade.set_fade("staging", Color(0, 0, 0, p_value))

func _ready():

	# This is the plotline between the scenes
	await $LoadingScreen.continue_pressed
	var tweenfadeloadscreen = get_tree().create_tween()
	tweenfadeloadscreen.tween_method(set_fade, 0.0, 1.0, 1.0)
	await tweenfadeloadscreen.finished
	$LoadingScreen.visible = false

	# Fade in and run the intro scene
	$IntroScene.visible = true
	var tweenfadeinintro = get_tree().create_tween()
	tweenfadeinintro.tween_method(set_fade, 1.0, 0.0, 1.0)
	var tweenfadeintrosound = get_tree().create_tween()
	$IntroScene/TrafficSound.volume_db = -50
	$IntroScene/TrafficSound.play()
	tweenfadeintrosound.tween_property($IntroScene/TrafficSound, "volume_db", 0.0, 3)
	await tweenfadeinintro.finished
	$IntroScene/MonkeyOrb.enabled = true
	await $IntroScene/MonkeyOrb.picked_up

	# Now transition to the monkey in the pond scene
	var tweenfadeintroscene = get_tree().create_tween()
	tweenfadeintroscene.tween_method(set_fade, 0.0, 1.0, 1.0)
	await tweenfadeintroscene.finished
	$IntroScene.visible = false
	$IntroScene/MonkeyOrb.enabled = true
	$IntroScene/TrafficSound.stop()
	$PondScene.visible = true
	$PondScene/Monkey/AnimationPlayer.play("KeyAction")
	$PondScene/MonkeyReflection/AnimationPlayer.play("KeyAction")
	var tweenfadeinpondscene = get_tree().create_tween()
	tweenfadeinpondscene.tween_method(set_fade, 1.0, 0.0, 1.0)
	$PondScene/AmbientSound.play()
	await tweenfadeinpondscene.finished
	print("Now in pond scene")



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
	var mat = $PondScene/Monkey/Monkey_Breathe.get_surface_override_material(0)
	mat.set_shader_parameter("noselight", nosepoint)
	var matrefl = $PondScene/MonkeyReflection/Monkey_Breathe.get_surface_override_material(0)
	nosepoint.y = -$XROrigin3D.transform.origin.y - nosepoint.y
	matrefl.set_shader_parameter("noselight", nosepoint)
	#mat.set_shader_parameter("noselight", Vector3(0,0.7,0.3))


	
func _input(event):
	if event is InputEventKey and  event.pressed and event.keycode == KEY_H:
		var tween = get_tree().create_tween()
		tween.tween_method(set_fade, 0.0, 1.0, 1.0)
		await tween.finished
		tween.kill()
		tween = get_tree().create_tween()
		tween.tween_method(set_fade, 1.0, 0.0, 1.0)
		await tween.finished
		tween.kill()
