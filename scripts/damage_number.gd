extends Node3D

enum Type { DAMAGE, CRIT, HEAL, MANA, STATUS }

@onready var label: Label3D = $Label3D

var velocity: Vector3 = Vector3(0, 2.6, 0)
var lifetime: float = 0.85
var timer: float = 0.0
var _initial_scale: float = 1.0

func setup_styled(amount_or_text: Variant, type: Type = Type.DAMAGE) -> void:
	if not label:
		label = $Label3D
	
	var txt = str(amount_or_text)
	var col = Color.WHITE
	var s_mult = 1.0
	
	match type:
		Type.DAMAGE:
			txt = "-%s" % txt if not txt.begins_with("-") and not txt.begins_with("💔") else txt
			col = Color(1.0, 0.25, 0.25, 1.0)
			s_mult = 1.1
		Type.CRIT:
			txt = "★ %s!" % txt
			col = Color(1.0, 0.88, 0.25, 1.0)
			s_mult = 1.45
		Type.HEAL:
			txt = "+%s" % txt if not txt.begins_with("+") and not txt.begins_with("💚") else txt
			col = Color(0.25, 1.0, 0.45, 1.0)
			s_mult = 1.2
		Type.MANA:
			txt = "+%s MP" % txt if not txt.contains("MP") else txt
			col = Color(0.25, 0.85, 1.0, 1.0)
			s_mult = 1.1
		Type.STATUS:
			col = Color(0.85, 0.5, 1.0, 1.0)
			s_mult = 1.15
	
	setup(txt, col, s_mult)

func setup(text: String, color: Color = Color.WHITE, scale_mult: float = 1.0) -> void:
	if not label:
		label = $Label3D
	label.text = text
	label.modulate = color
	label.outline_modulate = Color(0, 0, 0, 0.95)
	label.outline_size = 14
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_initial_scale = scale_mult
	scale = Vector3.ONE * _initial_scale

func _ready() -> void:
	# Random 3D offset to prevent overlapping text clusters
	position += Vector3(randf_range(-0.45, 0.45), randf_range(-0.15, 0.25), randf_range(-0.45, 0.45))
	velocity.x += randf_range(-0.75, 0.75)
	velocity.z += randf_range(-0.75, 0.75)

func _process(delta: float) -> void:
	timer += delta
	position += velocity * delta
	velocity.y = max(0.35, velocity.y - (delta * 2.8))
	
	var progress = timer / lifetime
	if progress >= 1.0:
		queue_free()
		return
	
	# Scale punch pop with ease-out, followed by gentle fade
	if progress < 0.18:
		var pop = 1.0 + sin((progress / 0.18) * PI * 0.5) * 0.45
		scale = Vector3.ONE * (_initial_scale * pop)
	else:
		var alpha = 1.0 - ((progress - 0.18) / 0.82)
		label.modulate.a = clamp(alpha, 0.0, 1.0)
