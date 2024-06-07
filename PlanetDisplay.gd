@tool
extends TextureRect
#provides an easy interface to the planet shader. most uniforms can be controlled
#by changing variables in this script


#--------------------------------CLIMATE--------------------------------
@export_group("climate")
##Used to mix between cold and warm color palettes.
##The planet is naturally warmer at the equator and colder at the poles
@export var temperature:float = 1.:
	set(v):
		temperature = v
		set_uniform("temp_multiplier",v)

##temps below this value freeze wether they are land or ocean
@export var freeze_temp:float:
	set(v):
		freeze_temp = v
		set_uniform("freeze_temp",v)

##elevations below this value are water
@export var sea_level:float:
	set(v):
		v = clamp(v,0.,1.)
		sea_level = v
		set_uniform("sea_level",sea_level)

##color palette for high temps
@export var warm_land_gradient:GradientTexture1D:
	set(v):
		warm_land_gradient = v
		set_uniform("warm_land_gradient",v)

##color palette for low temps
@export var cool_land_gradient:GradientTexture1D:
	set(v):
		cool_land_gradient = v
		set_uniform("cool_land_gradient",v)

##water depth gradient
@export var water_gradient:GradientTexture1D:
	set(v):
		water_gradient = v
		set_uniform("ocean_gradient",v)

##color palette for frozen temps
@export var ice_gradient:GradientTexture1D:
	set(v):
		ice_gradient = v
		set_uniform("ice_gradient",v)

#--------------------------------CLOUDS--------------------------------
@export_group("clouds")
##cloudiness. The amount of clouds
@export var cloudiness:float:
	set(v):
		v = clamp(v,0.,2.)
		cloudiness = v
		set_uniform("cloudiness",v)
##cloud opacity. leave at 0 as this system is being reworked
@export var cloud_opacity:float:
	set(v):
		v = clamp(v,0.,10.)
		cloud_opacity = v
		set_uniform("cloud_opacity",v)
##Cloud color bands
@export var cloud_layers:int:
	set(v):
		v = clamp(v,0.,100.)
		cloud_layers = v
		set_uniform("cloud_layers",v)
		
##cloud normal coefficient. Should be very small values like 0.005 for best result
@export var cloud_bumpiness:float:
	set(v):
		v = clamp(v,0.,1.)
		cloud_bumpiness = v
		set_uniform("cloud_normal_coeff",v)

##Cloud revolution speed
@export var cloud_speed:float:
	set(v):
		cloud_speed = v
		set_uniform("cloud_speed",v)

##cloud warping around y axis
@export var cloud_warp:float:
	set(v):
		v = clamp(v,-1.,1.)
		cloud_warp = v
		set_uniform("cloud_warp",v)
##color palette for clouds
@export var cloud_gradient:GradientTexture1D:
	set(v):
		cloud_gradient = v
		set_uniform("cloud_gradient",v)

#--------------------------------PHYSICAL--------------------------------
@export_group("Physical")



##normal coefficient in the shader.
@export var bumpiness:float:
	set(v):
		bumpiness = v
		set_uniform("normal_coeff",v)

##higher exponent = darker shading
@export var light_exp:float:
	set(v):
		v = clamp(v,0.1,4.0)
		light_exp = v
		set_uniform("light_exp",v)

###Angle the light comes from
#@export var light_angle:float:
	#set(v):
		#light_angle = v
		#set_uniform("light_angle",v)

##3D light axis
@export var light_direction:Vector3:
	set(v):
		light_direction = v
		set_uniform("light_dir",v)

##planet rotation speed
@export var turn_speed:float:
	set(v):
		turn_speed = v
		set_uniform("turn_rate",v)

##planet rotation axis
@export var axis:float:
	set(v):
		axis = v
		set_uniform("axis",v)

##texture coord offset for surface features
@export var surface_offset:Vector2:
	set(v):
		surface_offset = v
		set_uniform("offset",v)

##how many times to resample the noise for finer details each time.
##this is fucked up don't use it
@export var noise_feedback:int:
	set(v):
		v = clamp(v,0,10)
		noise_feedback = v
		set_uniform("noise_feedback",v)

##multiplier for noise resampling offset
@export var feedback_grain:float:
	set(v):
		v = clamp(v,0.1,100.)
		feedback_grain = v
		set_uniform("feedback_grain",v)

##multiplier for noise resampling offset
@export var feedback_soften:float:
	set(v):
		v = clamp(v,0.1,25.)
		feedback_soften = v
		set_uniform("feedback_soften",v)

##The amount of different colors allowed. Useful to eliminate ugly bluring. 
##Can also help give a more stylized look
@export var color_bands:int:
	set(v):
		v = clamp(v,0.1,50)
		color_bands = v
		set_uniform("color_bands",v)
#--------------------------------TEXTURES--------------------------------
@export_group("textures")
##surface elevation map
@export var surface_texture:Texture2D:#surface elevation map
	set(v):
		surface_texture = v
		texture_pixel_size = Vector2(1,1) / Vector2(v.get_width(),v.get_height())
		set_uniform("noise",v)

var texture_pixel_size:Vector2:
	set(v):
		texture_pixel_size = v
		set_uniform("px",v)

##cloud texture
@export var cloud_texture:Texture2D:
	set(v):
		cloud_texture = v
		set_uniform("cloud_noise",v)

##shorthand for setting a shader uniform
func set_uniform(name, v):
	material.set_shader_parameter(name,v)

#--------------------------------DEPRECATED--------------------------------
#@export var raymarch_bumpiness:float:
	#set(v):
		#raymarch_bumpiness = v
		#set_uniform("raymarch_bumpiness",v)
