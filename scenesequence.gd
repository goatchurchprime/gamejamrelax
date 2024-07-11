extends Node3D

@onready var xrorigin = get_node("../XROrigin3D")
@onready var headcontroller = XRHelpers.get_xr_camera(get_node("../XROrigin3D"))
@onready var leftcontroller = XRHelpers.get_left_controller(get_node("../XROrigin3D"))
@onready var rightcontroller = XRHelpers.get_right_controller(get_node("../XROrigin3D"))

const fadetag = "staging"
func set_fade(p_value : float, col : Color=Color.BLACK):
	XRToolsFade.set_fade(fadetag, Color(col, p_value))
func set_fade_blend(p_value : float, col1 : Color, col2 : Color):
	XRToolsFade.set_fade(fadetag, col1.blend(Color(col2, p_value)))
func set_master_volume_down(p_value : float):
	AudioServer.set_bus_volume_db(0, p_value)
	
@onready var monkeyeyeheightspot = $PondScene/MonkeyTop/Armature/Skeleton3D/Head_2/EyeheightSpot

var Dskiptomonkey = false
var Dautoadvanceloadscreen = true
func _ready():
	#
	# This is the master plotline between the scenes
	# "Please be seated comfortably"
	xrorigin.sethandorbs(Vector3(), Vector3(), 0.0, Color(Color.BLACK, 0.0))
	
	if Dautoadvanceloadscreen:
		await get_tree().create_timer(2.3).timeout
	else:
		await $LoadingScreen.continue_pressed
	
	# Fade out the loading screen
	var tweenfadeloadscreen = get_tree().create_tween()
	tweenfadeloadscreen.tween_method(set_fade, 0.0, 1.0, 1.0)
	await tweenfadeloadscreen.finished
	$LoadingScreen.visible = false

	# locate the orb in front of you within arm's reach
	var angrot = Vector2(headcontroller.global_transform.basis.z.x, headcontroller.global_transform.basis.z.z).angle_to(Vector2($IntroScene/MonkeyOrb.global_transform.basis.z.x, $IntroScene/MonkeyOrb.global_transform.basis.z.z))
	xrorigin.rotate_y(-angrot)
	const distanceorbbeloweye = 0.35
	const distanceorbinfrontofeye = 0.4
	var headoutvec = distanceorbinfrontofeye*Vector2(-headcontroller.global_transform.basis.z.x, -headcontroller.global_transform.basis.z.z).normalized()
	var orbtarget = headcontroller.global_position + Vector3(headoutvec.x, -distanceorbbeloweye, headoutvec.y)
	xrorigin.position += $IntroScene/MonkeyOrb.global_position - orbtarget

	# Fade in and run the intro scene
	if not Dskiptomonkey:
		$IntroScene.visible = true
		var tweenfadeinintro = get_tree().create_tween()
		tweenfadeinintro.tween_method(set_fade, 1.0, 0.0, 1.0)
		var tweenfadeintrosound = get_tree().create_tween()
		$IntroScene/TrafficSound.volume_db = -50
		$IntroScene/TrafficSound.play()
		tweenfadeintrosound.tween_property($IntroScene/TrafficSound, "volume_db", 0.0, 3)
		await tweenfadeinintro.finished
		$IntroScene/MonkeyOrb.enabled = true
	
	# now we busy-await for the hands to touch the orb for long enough
	var touchingscore = 0.0
	while touchingscore < 1.0 and not Dskiptomonkey:
		var orbpos = $IntroScene/MonkeyOrb.global_position
		var orbrad = $IntroScene/MonkeyOrb/Sphere.mesh.radius
		var orbdropoff = 0.04
		xrorigin.sethandorbs(orbpos, orbpos, orbrad, lerp(Color.YELLOW, Color.ORANGE_RED, touchingscore))
		var leftmiddleknucklepos = leftcontroller.get_node("LeftPhysicsHand/Hand_L/Armature/Skeleton3D/BoneMiddleProximal").global_position
		var rightmiddleknucklepos = rightcontroller.get_node("RightPhysicsHand/Hand_R/Armature/Skeleton3D/BoneMiddleProximal").global_position
		var dleftmiddleknucklepos = (leftmiddleknucklepos - orbpos).length() - orbrad
		var drightmiddleknucklepos = (rightmiddleknucklepos - orbpos).length() - orbrad
		if (dleftmiddleknucklepos < 0) or (drightmiddleknucklepos < 0):
			touchingscore = touchingscore*0.8
		elif (dleftmiddleknucklepos < orbdropoff) and (drightmiddleknucklepos < orbdropoff):
			touchingscore = touchingscore + 0.04
		await get_tree().create_timer(0.1).timeout
		if Input.is_key_pressed(KEY_C):
			break

	# The orb now rises to capture your attention and get you to lean back
	$IntroScene/MonkeyOrb/Pop.play()
	if not Dskiptomonkey:
		var tweenrisingorb = get_tree().create_tween()
		tweenrisingorb.tween_property($IntroScene/MonkeyOrb, "position", $IntroScene/MonkeyOrb.position + Vector3(0,0.5,0), 6.0).set_trans(Tween.TRANS_SINE)
		await get_tree().create_timer(2.0).timeout
				
		# Now fade out the intro scene (while the orb is still rising)
		var tweenfadeoutsound = get_tree().create_tween()
		tweenfadeoutsound.tween_property($IntroScene/TrafficSound, "volume_db", -50.0, 2)
		var tweenfadeintroscene = get_tree().create_tween()
		tweenfadeintroscene.tween_method(set_fade, 0.0, 1.0, 3.0)
		await tweenfadeintroscene.finished
		xrorigin.sethandorbs(Vector3(), Vector3(), 0.0, Color(Color.BLACK, 0.0))
		tweenrisingorb.kill()
		$IntroScene/TrafficSound.stop()
		$IntroScene.visible = false
		$IntroScene/MonkeyOrb.enabled = false
		$IntroScene/TrafficSound.stop()

	# Set the eye height with the monkey's eyes level with your eyes
	# this also needs to move us into facing the monkey head on if we are 
	# in a different part of the play area away from the origin
	const distancemonkeyeyeaboveeye = 0.22
	const distancemonkeyinfrontofeye = 1.8
	var headoutvecM = distancemonkeyinfrontofeye*Vector2(-headcontroller.global_transform.basis.z.x, -headcontroller.global_transform.basis.z.z).normalized()
	var monkeytarget = headcontroller.global_position + Vector3(headoutvecM.x, distancemonkeyeyeaboveeye, headoutvecM.y)
	xrorigin.position += monkeyeyeheightspot.global_position - monkeytarget

	# Now fade in the monkey scene
	$PondScene.visible = true
	await get_tree().create_timer(2.0).timeout
	var tweenfadeinpondscene = get_tree().create_tween()
	tweenfadeinpondscene.tween_method(set_fade, 1.0, 0.0, 4.0).set_trans(Tween.TRANS_SINE)
	$PondScene/AmbientSound.play()
	print("Now in pond scene")

	# This bit represents the whole of the mediation sequence (not yet done)
	$PondScene/MonkeyTop/AnimationPlayer.get_animation("Breathe").loop_mode = Animation.LOOP_NONE
	for i in range(10):
		breathtrackingscore = 0.0
		$PondScene/MonkeyTop/AnimationPlayer.play("Breathe")
		$PondScene/MonkeyBottom/AnimationPlayer.play("Breathe")
		var BBB = await $PondScene/MonkeyTop/AnimationPlayer.animation_finished
		print(i, " anim finished ", BBB, "  ", breathtrackingscore)
		if breathtrackingscore > 5.0:
			$PondScene/BreathMatchAccum.scale.x += 1

	# This is the final fade out and closing of the game
	$PondScene/MonkeyTop/AnimationPlayer.play("Breathe")
	$PondScene/MonkeyBottom/AnimationPlayer.play("Breathe")
	var tweenmastervolume = get_tree().create_tween()
	tweenmastervolume.tween_method(set_master_volume_down, 0.0, -50, 4.0)
	var tweenfinalfadegray = get_tree().create_tween()
	tweenfinalfadegray.tween_method(set_fade.bind(Color.WEB_GRAY), 0.0, 1.0, 5.0)
	tweenfinalfadegray.set_ease(Tween.EASE_IN_OUT)
	tweenfinalfadegray.tween_method(set_fade_blend.bind(Color.WEB_GRAY, Color.DIM_GRAY.darkened(0.8)), 0.0, 1.0, 4.0)
	await tweenfinalfadegray.finished

	# quit and kick you back out of the game!
	get_tree().quit()


var breathtrackingscore = 0.0
func _process(delta):
	var eyerayclos = Geometry3D.get_closest_point_to_segment_uncapped(monkeyeyeheightspot.global_position, headcontroller.global_position, headcontroller.global_position + headcontroller.global_transform.basis.z)
	var eyerayclosvec = monkeyeyeheightspot.global_position - eyerayclos
	eyerayclosvec.y *= 2  # more precision on vertical
	var eyeraydist = eyerayclosvec.length()
	if eyeraydist < 0.02:
		breathtrackingscore += delta
	$PondScene/BreathMatch.scale.x = breathtrackingscore
	
	var nosepoint = xrorigin.get_node("XRCamera3D/NosePointer").global_transform.origin
	var mat = $PondScene.monkeytopmaterial
	mat.set_shader_parameter("noselight", monkeyeyeheightspot.global_position)
	mat.set_shader_parameter("lightsquaredfac", eyeraydist*12)
	var matrefl = $PondScene.monkeyreflectmaterial
	nosepoint.y = -xrorigin.transform.origin.y - nosepoint.y
	
	matrefl.set_shader_parameter("noselight", monkeyeyeheightspot.global_position)
	#matrefl.set_shader_parameter("lightsquaredfac", eyeraydist*0.3)

	#mat.set_shader_parameter("noselight", Vector3(0,0.7,0.3))
