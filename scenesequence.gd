extends Node3D

@onready var headcontroller = XRHelpers.get_xr_camera(get_node("../XROrigin"))
@onready var leftcontroller = XRHelpers.get_left_controller(get_node("../XROrigin"))
@onready var rightcontroller = XRHelpers.get_right_controller(get_node("../XROrigin"))

func set_fade(p_value : float, col : Color=Color.BLACK):
	XRToolsFade.set_fade("staging", Color(col, p_value))

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

	# This quickly runs out the monkey and kicks you out of the whole game
	await get_tree().create_timer(8.0).timeout
	var tweenfinalfadegray = get_tree().create_tween()
	tweenfinalfadegray.tween_method(set_fade.bind(Color.WEB_GRAY), 0.0, 1.0, 5.0)
	tweenfinalfadegray.set_ease(Tween.EASE_IN_OUT)
	await tweenfinalfadegray.finished
	get_tree().quit()

func _process(delta):
	var xrorigin = get_node("../XROrigin3D")
	var nosepoint = xrorigin.get_node("XRCamera3D/NosePointer").global_transform.origin
	var mat = $PondScene/Monkey/Monkey_Breathe.get_surface_override_material(0)
	mat.set_shader_parameter("noselight", nosepoint)
	var matrefl = $PondScene/MonkeyReflection/Monkey_Breathe.get_surface_override_material(0)
	nosepoint.y = -xrorigin.transform.origin.y - nosepoint.y
	matrefl.set_shader_parameter("noselight", nosepoint)
	#mat.set_shader_parameter("noselight", Vector3(0,0.7,0.3))
