extends AudioStreamPlayer

@onready var microphoneidx = AudioServer.get_bus_index("MicrophoneBus")
var audioeffectcapture : AudioEffect
var audiosamplesize = 882

func _ready():
	assert (bus == "MicrophoneBus")
	audioeffectcapture = AudioServer.get_bus_effect(microphoneidx, 0)

func _process(delta):
	var audiosamples = null
	while audioeffectcapture.get_frames_available() > audiosamplesize:
		audiosamples = audioeffectcapture.get_buffer(audiosamplesize)
		#print(audiosamples[0])
	if audiosamples != null:
		var audiosampleframetextureimage = Image.create_from_data(len(audiosamples), 1, false, Image.FORMAT_RGF, audiosamples.to_byte_array())
		var audiosampleframetexture = ImageTexture.create_from_image(audiosampleframetextureimage)
		get_node("../VoiceGraph").get_surface_override_material(0).set_shader_parameter("voice", audiosampleframetexture)
