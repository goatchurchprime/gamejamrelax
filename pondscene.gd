extends Node3D

@onready var monkeytopmaterial = load("res://assets/monkeyshadertop.tres")
@onready var monkeyreflectmaterial = load("res://assets/monkeyshaderreflection.tres")

func _ready():
	for b in $MonkeyTop/Armature/Skeleton3D.get_children():
		if b.get_child_count() == 1:
			b.get_child(0).set_surface_override_material(0, monkeytopmaterial)
			b.get_child(0).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for b in $MonkeyBottom/Armature/Skeleton3D.get_children():
		if b.get_child_count() == 1:
			b.get_child(0).set_surface_override_material(0, monkeyreflectmaterial)
			b.get_child(0).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func set_waterfall_parameter(p_value : float, meshnode, shaderparam):
	meshnode.get_surface_override_material(0).set_shader_parameter(shaderparam, p_value)

func animatewaterfallcomingin():
	for meshnode in [$Scenery_02/BakedMesh/Root/Bw1/Bw1_0000, $Scenery_02/BakedMesh/Root/Bw2/Bw2_0000, 
					 $Scenery_02/BakedMesh/Root/Ww1/Ww1_0000, $Scenery_02/BakedMesh/Root/Ww2/Ww2_0000 ]:
		meshnode.visible = true
		var tweenwatershader = get_tree().create_tween()
		tweenwatershader.tween_method(set_waterfall_parameter.bind(meshnode, "watercutoff"), 5.0, 0.0, 8.0)
		var jaggywatershader = get_tree().create_tween()
		jaggywatershader.tween_method(set_waterfall_parameter.bind(meshnode, "jaggy"), 0.3, 0.3, 5.0)
		jaggywatershader.tween_method(set_waterfall_parameter.bind(meshnode, "jaggy"), 0.3, 0.0, 3.0)
		await tweenwatershader.finished
		
