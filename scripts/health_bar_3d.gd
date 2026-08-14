extends Node3D

var _bg: Sprite3D = null
var _fill: Sprite3D = null
var _max_health: float = 100.0


func _ready() -> void:
	var white_tex := AssetLoader.load_asset("low/healthbar3d_64x12.png", func(): return _make_white_texture())

	_bg = Sprite3D.new()
	_bg.texture = white_tex
	_bg.modulate = Color(0.2, 0.2, 0.2, 0.8)
	_bg.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bg.pixel_size = 0.04
	add_child(_bg)

	_fill = Sprite3D.new()
	_fill.texture = white_tex
	_fill.modulate = Color(0.2, 1.0, 0.2, 0.9)
	_fill.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_fill.pixel_size = 0.04
	_fill.position.z = 0.001
	add_child(_fill)


func _make_white_texture() -> ImageTexture:
	var img := Image.create(64, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	return ImageTexture.create_from_image(img)


func setup(max_hp: float) -> void:
	_max_health = max_hp


func update_health(current: float, max_hp: float) -> void:
	if _fill == null:
		return
	var pct := clampf(current / max_hp, 0.0, 1.0)
	_fill.scale.x = pct
	_fill.position.x = (pct - 1.0) * 0.5 * 32.0 * _fill.pixel_size

	_fill.position.x = (pct - 1.0) * 0.5 * 64.0 * _fill.pixel_size

	if pct < 0.3:
		_fill.modulate = Color(1.0, 0.2, 0.2, 0.9)
	elif pct < 0.6:
		_fill.modulate = Color(1.0, 0.8, 0.2, 0.9)
	else:
		_fill.modulate = Color(0.2, 1.0, 0.2, 0.9)
