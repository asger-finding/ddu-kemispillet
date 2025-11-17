extends ColorRect

@export var camera_reference: Camera2D # Parallax should follow the camera transform
@export var parallax_speed: float = 0.2  # How fast the background moves relative to camera

var shader_material: ShaderMaterial
var original_size: Vector2
var original_zoom: float
var original_paper_scale: float

func _ready():
	assert(material is ShaderMaterial, "Node needs a ShaderMaterial with the crumpled paper shader")
	shader_material = material

	original_size = size
	original_zoom = camera_reference.zoom.x
	original_paper_scale = shader_material.get_shader_parameter("paper_scale")

func _process(_delta):
	if camera_reference and shader_material:
		var camera_pos = camera_reference.global_position
		
		size = original_size / camera_reference.zoom.x
		position = camera_pos - size / 2
		
		shader_material.set_shader_parameter("camera_offset", camera_pos * parallax_speed)
		# FIXME: needs to shift xy in shader to work
		# shader_material.set_shader_parameter("paper_scale", 1 / camera_reference.zoom.x * original_zoom * original_paper_scale)
