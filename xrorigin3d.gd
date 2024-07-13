extends XROrigin3D

func sethandorbs(lefthandorb, righthandorb, handorbrad, handorbcolour):
	var matleft = $XRController3DLeft/LeftPhysicsHand.hand_material_override
	matleft.set_shader_parameter("orbcentrerelativetohand", $XRController3DLeft/LeftPhysicsHand/Hand_L.global_transform.affine_inverse()*lefthandorb)
	matleft.set_shader_parameter("orbcentre", lefthandorb)

	var matright = $XRController3DRight/RightPhysicsHand.hand_material_override
	matright.set_shader_parameter("orbcentrerelativetohand", $XRController3DRight/RightPhysicsHand/Hand_R.global_transform.affine_inverse()*righthandorb)
	matright.set_shader_parameter("orbcentre", righthandorb)

	matleft.set_shader_parameter("orbrad", handorbrad)
	matright.set_shader_parameter("orbrad", handorbrad)
	matleft.set_shader_parameter("orbbrightcolour", handorbcolour)
	matright.set_shader_parameter("orbbrightcolour", handorbcolour)
	
