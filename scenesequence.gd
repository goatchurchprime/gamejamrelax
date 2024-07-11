extends Node3D

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
	

var Dskiptomonkey = false
func _ready():
	if Dskiptomonkey:
		$PondScene/MonkeyTop/AnimationPlayer.play("Breathe")
		$PondScene/MonkeyBottom/AnimationPlayer.play("Breathe")
		$IntroScene/TrafficSound.play()
		var tweenfinalfadegray = get_tree().create_tween()
		tweenfinalfadegray.tween_method(set_fade.bind(Color.WEB_GRAY), 0.0, 1.0, 5.0)
		var tween = get_tree().create_tween()
		tween.tween_method(set_master_volume_down, 0.0, -50, 4)
		tweenfinalfadegray.set_ease(Tween.EASE_IN_OUT)
		tweenfinalfadegray.tween_method(set_fade_blend.bind(Color.WEB_GRAY, Color.DIM_GRAY.darkened(0.5)), 0.0, 1.0, 3.0)
		await tweenfinalfadegray.finished
		get_tree().quit()

	#
	# This is the master plotline between the scenes
	#  (fix this)
	await $LoadingScreen.continue_pressed
	
	# Fade out the loading screen
	var tweenfadeloadscreen = get_tree().create_tween()
	tweenfadeloadscreen.tween_method(set_fade, 0.0, 1.0, 1.0)
	await tweenfadeloadscreen.finished
	$LoadingScreen.visible = false

	# Here we must make sure that the player is in reach of the orb
	# with both hands central before we fade it in
	# They should touch both hands into it before it gets activated
	# (The orb will light up as their both hands get close)

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

	# Now fade out the intro scene
	var tweenfadeoutsound = get_tree().create_tween()
	tweenfadeoutsound.tween_property($IntroScene/TrafficSound, "volume_db", -50.0, 2)
	var tweenfadeintroscene = get_tree().create_tween()
	tweenfadeintroscene.tween_method(set_fade, 0.0, 1.0, 3.0)
	await tweenfadeintroscene.finished
	$IntroScene/TrafficSound.stop()
	$IntroScene.visible = false
	$IntroScene/MonkeyOrb.enabled = false
	$IntroScene/TrafficSound.stop()

	# Set the eye height with the monkey's eyes level with your eyes
	# this also needs to move us into facing the monkey head on if we are 
	# in a different part of the play area away from the origin
	get_node("../XROrigin3D").position.y -= headcontroller.global_position.y - $PondScene/EyeheightSpot.global_position.y

	# Now fade in the monkey scene
	$PondScene.visible = true
	$PondScene/MonkeyTop/AnimationPlayer.play("Breathe")
	$PondScene/MonkeyBottom/AnimationPlayer.play("Breathe")
	await get_tree().create_timer(2.0).timeout
	var tweenfadeinpondscene = get_tree().create_tween()
	tweenfadeinpondscene.tween_method(set_fade, 1.0, 0.0, 4.0)
	tweenfadeinpondscene.set_ease(Tween.EASE_IN)
	$PondScene/AmbientSound.play()
	await tweenfadeinpondscene.finished
	print("Now in pond scene")

	# This bit represents the whole of the mediation sequence (not yet done)
	await get_tree().create_timer(8.0).timeout

	# This is the final fade out and closing of the game
	var tweenmastervolume = get_tree().create_tween()
	tweenmastervolume.tween_method(set_master_volume_down, 0.0, -50, 4.0)
	var tweenfinalfadegray = get_tree().create_tween()
	tweenfinalfadegray.tween_method(set_fade.bind(Color.WEB_GRAY), 0.0, 1.0, 5.0)
	tweenfinalfadegray.set_ease(Tween.EASE_IN_OUT)
	tweenfinalfadegray.tween_method(set_fade_blend.bind(Color.WEB_GRAY, Color.DIM_GRAY.darkened(0.8)), 0.0, 1.0, 4.0)
	await tweenfinalfadegray.finished

	# quit and kick you back out of the game!
	get_tree().quit()


func _process(delta):
	var xrorigin = get_node("../XROrigin3D")
	var nosepoint = xrorigin.get_node("XRCamera3D/NosePointer").global_transform.origin
	var mat = $PondScene.monkeytopmaterial
	mat.set_shader_parameter("noselight", nosepoint)
	var matrefl = $PondScene.monkeyreflectmaterial
	nosepoint.y = -xrorigin.transform.origin.y - nosepoint.y
	matrefl.set_shader_parameter("noselight", nosepoint)
	#mat.set_shader_parameter("noselight", Vector3(0,0.7,0.3))
