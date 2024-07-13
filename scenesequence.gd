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
func set_monkey_eyelids(p_value : float):
	$PondScene/MonkeyTop/Armature/Skeleton3D/Head_2/Head_2.set_blend_shape_value(0, p_value)

func set_monkey_arms_out(p_value : float):
	$PondScene/AnimationTree.set("parameters/ArmsOutBlend/blend_amount", p_value)


@onready var monkeyeyeheightspot = $PondScene/MonkeyTop/Armature/Skeleton3D/Head_2/EyeheightSpot
@onready var monkeyeyeprojectedspot = $PondScene/MonkeyTop/Armature/Skeleton3D/Head_2/EyeheightSpot/EyeprojectedSpot
@onready var monkeybreathing = $PondScene/MonkeyTop/Armature/Skeleton3D/Head_2/Breathing

var Dskiptomonkey = false
var Dautoadvanceloadscreen = true
const distancemonkeyeyeaboveeye = 0.12
const distancemonkeyinfrontofeye = 1.8
var monkeyeyetargetradius = 0.04
var pushbackbreathtargetdistance = 1.3
var pushbackbreathtargetenlargen = 5.0  # need to counteract shrinking by perspective

@onready var leftmiddleknuckleemitter = leftcontroller.get_node("LeftPhysicsHand/Hand_L/Armature/Skeleton3D/BoneMiddleProximal/GPUParticles")
@onready var rightmiddleknuckleemitter = rightcontroller.get_node("RightPhysicsHand/Hand_R/Armature/Skeleton3D/BoneMiddleProximal/GPUParticles")

@onready var skyapartment = load("res://assets/skyapartment.tres")
@onready var skypond = load("res://assets/skypond.tres")
@onready var skyintro = load("res://assets/skyintro.tres")

func _ready():
	#
	# This is the master plotline between the scenes
	# "Please be seated comfortably"
	xrorigin.sethandorbs(Vector3(), Vector3(), 0.0, Color(Color.BLACK, 0.0))
	
	$IntroScene.visible = false
	$PondScene.visible = false
	$LoadingScreen.visible = true
	get_node("../WorldEnvironment").environment.sky = skyintro
	if Dautoadvanceloadscreen:
		if not Dskiptomonkey:
			for i in range(11):
				await get_tree().create_timer(0.5).timeout
				$LoadingScreen.progress = i/10.0
	else:
		await $LoadingScreen.continue_pressed
	
	# Fade out the loading screen
	if not Dskiptomonkey:
		$LoadingScreen.visible = true
		var tweenfadeloadscreen = get_tree().create_tween()
		tweenfadeloadscreen.tween_method(set_fade, 0.0, 1.0, 1.0)
		await tweenfadeloadscreen.finished
	$LoadingScreen.visible = false

	# locate the orb in front of you within arm's reach
	var angrot = Vector2(headcontroller.global_transform.basis.z.x, headcontroller.global_transform.basis.z.z).angle_to(Vector2($IntroScene/MonkeyOrb.global_transform.basis.z.x, $IntroScene/MonkeyOrb.global_transform.basis.z.z))
	xrorigin.rotate_y(-angrot)
	const distanceorbbeloweye = 0.35
	const distanceorbinfrontofeye = 0.4
	var headcontrollerhorizontalvec = Vector2(-headcontroller.global_transform.basis.z.x, -headcontroller.global_transform.basis.z.z).normalized()
	var headoutvec = distanceorbinfrontofeye*headcontrollerhorizontalvec
	var orbtarget = headcontroller.global_position + Vector3(headoutvec.x, -distanceorbbeloweye, headoutvec.y)
	xrorigin.position += $IntroScene/MonkeyOrb.global_position - orbtarget

	# Fade in and run the intro scene
	if not Dskiptomonkey:
		get_node("../WorldEnvironment").environment.sky = skyapartment
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
	rightmiddleknuckleemitter.emitting = true
	leftmiddleknuckleemitter.emitting = true
	#$IntroScene/MonkeyOrb/ElectricSizzle.play()
	$IntroScene/MonkeyOrb/ElectricSizzle.stream_paused = true
	while touchingscore < 1.0 and not Dskiptomonkey and not Input.is_key_pressed(KEY_C):
		var orbpos = $IntroScene/MonkeyOrb.global_position
		var orbrad = $IntroScene/MonkeyOrb/Sphere.mesh.radius
		var orbdropoff = 0.04
		var leftmiddleknucklepos = leftcontroller.get_node("LeftPhysicsHand/Hand_L/Armature/Skeleton3D/BoneMiddleProximal").global_position
		var rightmiddleknucklepos = rightcontroller.get_node("RightPhysicsHand/Hand_R/Armature/Skeleton3D/BoneMiddleProximal").global_position
		var dleftmiddleknucklepos = (leftmiddleknucklepos - orbpos).length() - orbrad
		var drightmiddleknucklepos = (rightmiddleknucklepos - orbpos).length() - orbrad
		rightmiddleknuckleemitter.amount_ratio = 0.0 if drightmiddleknucklepos < 0 else max(0, 1.0 - drightmiddleknucklepos/orbdropoff);
		leftmiddleknuckleemitter.amount_ratio = 0.0 if dleftmiddleknucklepos < 0 else max(0, 1.0 - dleftmiddleknucklepos/orbdropoff);

		if (dleftmiddleknucklepos < 0) or (drightmiddleknucklepos < 0):
			touchingscore = touchingscore*0.8
			$IntroScene/MonkeyOrb/ElectricSizzle.stream_paused = true
		elif (dleftmiddleknucklepos < orbdropoff) and (drightmiddleknucklepos < orbdropoff):
			touchingscore = touchingscore + 0.02
			if not $IntroScene/MonkeyOrb/ElectricSizzle.playing:
				$IntroScene/MonkeyOrb/ElectricSizzle.play()
			$IntroScene/MonkeyOrb/ElectricSizzle.stream_paused = false
		else:
			touchingscore = touchingscore*0.9
			$IntroScene/MonkeyOrb/ElectricSizzle.stream_paused = true

		var handorbcolour = lerp(Color.YELLOW, Color.ORANGE_RED, touchingscore)
		if fmod(touchingscore*8, 1.0) > 0.8:
			handorbcolour = Color.WHITE
		xrorigin.sethandorbs(orbpos, orbpos, orbrad, handorbcolour)
		await get_tree().create_timer(0.1).timeout

	# The orb now rises to capture your attention and get you to lean back
	$IntroScene/MonkeyOrb/ElectricSizzle.stop()
	$IntroScene/MonkeyOrb/Pop.play()
	rightmiddleknuckleemitter.emitting = false
	leftmiddleknuckleemitter.emitting = false
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
		tweenrisingorb.kill()
		$IntroScene/TrafficSound.stop()
		$IntroScene.visible = false
		$IntroScene/MonkeyOrb.enabled = false

	# set the hands the same colour as in the orb (so they are not distracting)
	xrorigin.sethandorbs(Vector3(), Vector3(), 0.0, Color(Color.BLACK, 0.0))
	rightcontroller.get_node("RightPhysicsHand").hand_material_override.set_shader_parameter("orbrad", 100.0)
	leftcontroller.get_node("LeftPhysicsHand").hand_material_override.set_shader_parameter("orbrad", 100.0)
	headcontroller.get_node("NosePointer").visible = true

	# Set the eye height with the monkey's eyes level with your eyes
	# this also needs to move us into facing the monkey head on if we are 
	# in a different part of the play area away from the origin
	var headoutvecM = distancemonkeyinfrontofeye*headcontrollerhorizontalvec
	var monkeytarget = headcontroller.global_position + Vector3(headoutvecM.x, distancemonkeyeyeaboveeye, headoutvecM.y)
	xrorigin.position += monkeyeyeheightspot.global_position - monkeytarget
	monkeyeyeprojectedspot.position.z = distancemonkeyinfrontofeye*0.5
	monkeyeyeprojectedspot.scale = Vector3(monkeyeyetargetradius,monkeyeyetargetradius,monkeyeyetargetradius)
	$PondScene/EyeprojectedSpotDeep.scale = monkeyeyeprojectedspot.scale*pushbackbreathtargetenlargen

	# Now fade in the monkey scene
	$PondScene.visible = true
	get_node("../WorldEnvironment").environment.sky = skypond
	if not Dskiptomonkey:
		await get_tree().create_timer(0.2).timeout
		var tweenfadeinpondscene = get_tree().create_tween()
		tweenfadeinpondscene.tween_method(set_fade, 1.0, 0.0, 4.0).set_trans(Tween.TRANS_SINE)
	$PondScene/AmbientSound.play()
	print("Now in pond scene")

	#$PondScene.animatewaterfallcomingin()
	#$PondScene/KoiLips.triggerkoi() 
	
	# This bit represents the whole of the mediation sequence (not yet done)
	$PondScene/MonkeyTop/AnimationPlayer.get_animation("Breathe").loop_mode = Animation.LOOP_NONE
	var successfulbreaths = 0
	const breathstokoi = 4         # 32secs
	const breathstowaterfall = 12  # 1m36
	const breathstosnowstorm = 20  # 2m40
	const breathstosnowstormdouble = 24 # 3m12
	const breathstosnowstormrepelling = 30 # 4m
	const breathstosnowstormclear = 36 # 4m48
	const breathstofinish = 40  # 5m20
	
	var breathschapterlo = 0
	var breathschapterhi = breathstowaterfall
	var prevmonkeyarmsoutfac = 0.0
	while successfulbreaths < breathstofinish:
		breathtrackingscore = 0.0
#		$PondScene/MonkeyTop/AnimationPlayer.play("Breathe")
		$PondScene/AnimationTree.set("parameters/BreatheSeek/seek_request", 0)
		$PondScene/MonkeyBottom/AnimationPlayer.play("Breathe")
		monkeybreathing.play(0.2)

		# Here we want to wait till a breath cycle has finished, 
		# But we are doing it by time as there is no signal we have found yet
		#var BBB = await $PondScene/MonkeyTop/AnimationPlayer.animation_finished
		var BBB = await get_tree().create_timer(breathtrackingtime).timeout

		print($PondScene/BreathMatchAccum.scale.x, " anim finished ", BBB, "  ", breathtrackingscore)
		if breathtrackingscore > breathtrackinggoodtime:
			$PondScene/BreathMatchAccum.scale.x += 1
			successfulbreaths += 1

			if successfulbreaths == breathstokoi:
				$PondScene/KoiLips.triggerkoi() 
				breathschapterlo = successfulbreaths
				breathschapterhi = breathstowaterfall

			if successfulbreaths == breathstowaterfall:
				$PondScene.animatewaterfallcomingin()
				breathschapterlo = successfulbreaths
				breathschapterhi = breathstosnowstorm

			if successfulbreaths == breathstosnowstorm:
				$PondScene/SnowParticles.emitting = true
				#$PondScene/SnowParticles.amount_ratio = 0.2
				breathschapterlo = successfulbreaths
				breathschapterhi = breathstofinish

			if successfulbreaths == breathstosnowstormdouble:
				$PondScene/SnowParticles.amount_ratio = 1.0
			if successfulbreaths == breathstosnowstormrepelling:
				$PondScene/GPUParticlesAttractorSphere3D.strength = -1.0
				$PondScene/SnowParticles.amount_ratio = 0.5
			if successfulbreaths == breathstosnowstormclear:
				$PondScene/SnowParticles.emitting = false

			var tweenarmsout = get_tree().create_tween()
			var monkeyarmsoutfac = (successfulbreaths - breathschapterlo)/(breathschapterhi - breathschapterlo - 1.0)
			tweenarmsout.tween_method(set_monkey_arms_out, prevmonkeyarmsoutfac, monkeyarmsoutfac, 0.5)
			prevmonkeyarmsoutfac = monkeyarmsoutfac

	# Monkey moves half speed and slowly opens eyes 
	$PondScene/AnimationTree.set("parameters/EyesBlend/blend_amount", 1.0)
	$PondScene/MonkeyTop/AnimationPlayer.speed_scale = 0.5
	$PondScene/MonkeyBottom/AnimationPlayer.speed_scale = 0.5
	$PondScene/EyeprojectedSpotDeep.visible = false
	headcontroller.get_node("NosePointer").visible = false
	$PondScene/MonkeyTop/AnimationPlayer.play("Breathe")
	$PondScene/MonkeyBottom/AnimationPlayer.play("Breathe")
	await get_tree().create_timer(4.5).timeout

	# Final fade out and exit of game
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
const breathtrackingtime = 8.0
const breathtrackinggoodtime = 5.0

const eyeraydistfocusfactor = 23
func _process(delta):
	var eyerayclos = Geometry3D.get_closest_point_to_segment_uncapped(monkeyeyeprojectedspot.global_position, headcontroller.global_position, headcontroller.global_position + headcontroller.global_transform.basis.z)
	var eyerayclosvec = monkeyeyeprojectedspot.global_position - eyerayclos
	var eyeraydist = eyerayclosvec.length() 
	if eyeraydist < monkeyeyetargetradius or Input.is_key_pressed(KEY_C):
		breathtrackingscore += delta
	$PondScene/BreathMatch.scale.x = breathtrackingscore
	var eyeprojectvec = (monkeyeyeprojectedspot.global_position - headcontroller.global_position).normalized()
	$PondScene/EyeprojectedSpotDeep.global_position = monkeyeyeprojectedspot.global_position + pushbackbreathtargetdistance*eyeprojectvec
	var breathtrackingprop = clamp(breathtrackingscore/breathtrackinggoodtime, 0.0, 1.0)
	$PondScene/EyeprojectedSpotDeep/ExpandingSpot.scale = Vector3(breathtrackingprop, breathtrackingprop, breathtrackingprop)
	
	var mat = $PondScene.monkeytopmaterial
	mat.set_shader_parameter("noselight", monkeyeyeheightspot.global_position)
	mat.set_shader_parameter("lightsquaredfac", eyeraydist*eyeraydistfocusfactor)

	var matrefl = $PondScene.monkeyreflectmaterial
	matrefl.set_shader_parameter("noselight", monkeyeyeheightspot.global_position*Vector3(1,-1,1))
	matrefl.set_shader_parameter("lightsquaredfac", eyeraydist*eyeraydistfocusfactor)

	#mat.set_shader_parameter("noselight", Vector3(0,0.7,0.3))
