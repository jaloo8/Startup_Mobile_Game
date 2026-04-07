class_name PixelCharacter
extends TextureRect
## Procedural 14×20 pixel-art office worker.
##
## Deterministic appearance seeded from employee UID: skin tone, hair color,
## hair style, optional glasses. Shirt color = assignment. Two-frame animation
## cycle driven by a looping tween.
##
## 14×20 gives enough room for: hair detail, visible neck, collar, belt line,
## separated legs, and distinct arm poses — while staying firmly in the
## chunky pixel-art register (Kairosoft / Tiny Tower).


# ---------------------------------------------------------------------------
# Geometry
# ---------------------------------------------------------------------------

const CHAR_W := 14
const CHAR_H := 20


# ---------------------------------------------------------------------------
# Palettes
# ---------------------------------------------------------------------------

const SKIN_TONES: Array[Color] = [
	Color(0.94, 0.80, 0.67),
	Color(0.87, 0.71, 0.55),
	Color(0.75, 0.57, 0.42),
	Color(0.60, 0.43, 0.31),
	Color(0.45, 0.30, 0.20),
]

const HAIR_COLORS: Array[Color] = [
	Color(0.15, 0.12, 0.10),   # black
	Color(0.35, 0.22, 0.14),   # dark brown
	Color(0.55, 0.38, 0.22),   # brown
	Color(0.78, 0.58, 0.30),   # sandy
	Color(0.88, 0.72, 0.38),   # blonde
	Color(0.62, 0.28, 0.18),   # auburn
	Color(0.72, 0.72, 0.72),   # grey
]

## 0=short crop, 1=medium side-part, 2=long, 3=spiky, 4=bun
const HAIR_STYLE_COUNT := 5

const SHIRT_COLORS := {
	0: Color(0.32, 0.72, 0.44),  # FEATURES
	1: Color(0.88, 0.50, 0.35),  # BUGS
	2: Color(0.82, 0.70, 0.30),  # TECH_DEBT
	3: Color(0.36, 0.62, 0.88),  # INFRA
	4: Color(0.64, 0.48, 0.86),  # RND
	5: Color(0.55, 0.55, 0.60),  # UNASSIGNED
}

const PANTS_COLOR   := Color(0.22, 0.26, 0.34)
const PANTS_SHADOW  := Color(0.17, 0.20, 0.28)
const BELT_COLOR    := Color(0.30, 0.28, 0.24)
const SHOE_COLOR    := Color(0.18, 0.18, 0.20)
const GLASSES_COLOR := Color(0.80, 0.82, 0.90, 0.92)
const EYE_WHITE     := Color(0.92, 0.92, 0.94)
const EYE_PUPIL     := Color(0.12, 0.12, 0.16)


# ---------------------------------------------------------------------------
# Instance state
# ---------------------------------------------------------------------------

var _anim_tween: Tween
var _frames: Array[ImageTexture] = []
var _frame_index: int = 0
var _assignment: int = 5


# ---------------------------------------------------------------------------
# Factory
# ---------------------------------------------------------------------------

static func create(emp: EmployeeData, display_height: float = 20.0) -> PixelCharacter:
	var pc := PixelCharacter.new()
	if emp == null:
		push_warning("PixelCharacter.create(): null employee — returning blank sprite")
		return pc
	pc._assignment = emp.assignment
	var sf := display_height / float(CHAR_H)
	pc.custom_minimum_size = Vector2(CHAR_W * sf, display_height)
	pc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pc.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var h := absi(hash(emp.employee_uid))
	var skin  := SKIN_TONES[h % SKIN_TONES.size()]
	var hair  := _pick_hair(h, emp.age)
	var shirt := SHIRT_COLORS.get(emp.assignment, SHIRT_COLORS[5])
	var style := (h / 7) % HAIR_STYLE_COUNT
	var glasses: bool = (h / 31) % 5 == 0  # ~20% chance

	pc._frames = _make_frames(skin, hair, shirt, style, glasses, emp.assignment)
	if not pc._frames.is_empty():
		pc.texture = pc._frames[0]
	return pc


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_start_anim()

func _exit_tree() -> void:
	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()


# ---------------------------------------------------------------------------
# Animation
# ---------------------------------------------------------------------------

func _start_anim() -> void:
	if _frames.size() < 2:
		return
	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()

	var dur: float
	match _assignment:
		0: dur = 0.38   # FEATURES — brisk typing
		1: dur = 0.28   # BUGS — jittery
		2: dur = 0.52   # TECH_DEBT — methodical
		3: dur = 0.48   # INFRA — steady
		4: dur = 0.72   # RND — contemplative
		_: dur = 0.90   # UNASSIGNED — lazy bob

	_frame_index = 0
	_anim_tween = create_tween().set_loops()
	_anim_tween.tween_callback(_swap_frame).set_delay(dur)


func _swap_frame() -> void:
	_frame_index = (_frame_index + 1) % _frames.size()
	texture = _frames[_frame_index]


# ---------------------------------------------------------------------------
# Generation helpers
# ---------------------------------------------------------------------------

static func _pick_hair(h: int, age: int) -> Color:
	if age >= 55:
		return HAIR_COLORS[6]
	return HAIR_COLORS[(h / 3) % (HAIR_COLORS.size() - 1)]


static func _make_frames(skin: Color, hair: Color, shirt: Color,
		hair_style: int, glasses: bool, assignment: int) -> Array[ImageTexture]:
	var out: Array[ImageTexture] = []
	for pose in [0, 1]:
		var img := _draw(skin, hair, shirt, hair_style, glasses, assignment, pose)
		out.append(ImageTexture.create_from_image(img))
	return out


# ---------------------------------------------------------------------------
# Pixel drawing — the actual character renderer
# ---------------------------------------------------------------------------

static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and x < CHAR_W and y >= 0 and y < CHAR_H:
		img.set_pixel(x, y, c)


static func _rect(img: Image, x0: int, y0: int, w: int, h: int, c: Color) -> void:
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			_px(img, x, y, c)


static func _draw(skin: Color, hair: Color, shirt: Color,
		hair_style: int, glasses: bool, assignment: int, pose: int) -> Image:
	var img := Image.create(CHAR_W, CHAR_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var skin_shadow := skin.darkened(0.12)
	var hair_hi := hair.lightened(0.12)
	var hair_shadow := hair.darkened(0.12)
	var shirt_hi := shirt.lightened(0.10)
	var shirt_shadow := shirt.darkened(0.15)

	# Shared coordinates.
	var cx := CHAR_W / 2  # 7 — center X
	var head_w := 6
	var head_x := cx - head_w / 2  # 4
	var torso_w := 8
	var torso_x := cx - torso_w / 2  # 3

	# =================================================================
	# HAIR  (rows 0–2, varies by style)
	# =================================================================
	match hair_style:
		0:  # Short crop — 6px wide, 2 rows, flat top.
			_rect(img, head_x, 0, head_w, 2, hair)
			# Highlight on top-left.
			_px(img, head_x + 1, 0, hair_hi)
		1:  # Medium side-part — 7px wide, 3 rows, swept right.
			_rect(img, head_x, 0, head_w + 1, 2, hair)
			_rect(img, head_x, 2, head_w, 1, hair_shadow)
			# Part line.
			_px(img, head_x + 2, 0, hair_shadow)
			_px(img, head_x + 1, 0, hair_hi)
		2:  # Long — 8px wide, 3 rows + side strands down to row 6.
			_rect(img, head_x - 1, 0, head_w + 2, 3, hair)
			_px(img, head_x, 0, hair_hi)
			for y in range(3, 7):
				_px(img, head_x - 1, y, hair_shadow)
				_px(img, head_x + head_w, y, hair_shadow)
		3:  # Spiky — 6px wide, 3 rows with jagged top edge.
			_rect(img, head_x, 1, head_w, 2, hair)
			# Spikes on row 0: every other pixel.
			for x in range(head_x, head_x + head_w):
				if (x + head_x) % 2 == 0:
					_px(img, x, 0, hair)
			_px(img, head_x + 1, 0, hair_hi)
		4:  # Bun — 6px wide crop + 3px bun on top.
			_rect(img, head_x, 1, head_w, 2, hair)
			# Bun: 4px wide centered, rows -1 to 0 (row 0 only since can't go negative).
			_rect(img, cx - 2, 0, 4, 1, hair)
			_px(img, cx - 1, 0, hair_hi)

	# =================================================================
	# HEAD  (rows 2–6: 6px wide, 5 rows)
	# =================================================================
	_rect(img, head_x, 2, head_w, 5, skin)
	# Shadow on right edge of face.
	for y in range(2, 7):
		_px(img, head_x + head_w - 1, y, skin_shadow)

	# Eyes (row 4) — white + pupil for more expression.
	var ey := 4
	# Left eye.
	_px(img, head_x + 1, ey, EYE_WHITE)
	_px(img, head_x + 2, ey, EYE_PUPIL)
	# Right eye.
	_px(img, head_x + 3, ey, EYE_PUPIL)
	_px(img, head_x + 4, ey, EYE_WHITE)

	# Glasses (if applicable) — single-pixel frame around each eye.
	if glasses:
		_px(img, head_x + 1, ey - 1, GLASSES_COLOR)
		_px(img, head_x + 2, ey - 1, GLASSES_COLOR)
		_px(img, head_x + 1, ey + 1, GLASSES_COLOR)
		_px(img, head_x + 2, ey + 1, GLASSES_COLOR)
		_px(img, head_x + 3, ey - 1, GLASSES_COLOR)
		_px(img, head_x + 4, ey - 1, GLASSES_COLOR)
		_px(img, head_x + 3, ey + 1, GLASSES_COLOR)
		_px(img, head_x + 4, ey + 1, GLASSES_COLOR)
		# Bridge.
		_px(img, head_x + 2, ey - 1, GLASSES_COLOR)
		_px(img, head_x + 3, ey - 1, GLASSES_COLOR)

	# Mouth hint (row 5) — subtle 2px line, slightly darker than skin.
	_px(img, head_x + 2, 5, skin_shadow)
	_px(img, head_x + 3, 5, skin_shadow)

	# =================================================================
	# NECK  (row 7: 2px wide centered)
	# =================================================================
	_px(img, cx - 1, 7, skin)
	_px(img, cx, 7, skin_shadow)

	# =================================================================
	# TORSO + COLLAR  (rows 8–13)
	# =================================================================
	var ty := 8
	# Collar (row 8): shirt color, 2px notch at center for V-neck look.
	_rect(img, torso_x, ty, torso_w, 1, shirt_hi)
	_px(img, cx - 1, ty, shirt.lightened(0.25))
	_px(img, cx, ty, shirt.lightened(0.25))

	# Main torso (rows 9–12).
	_rect(img, torso_x, ty + 1, torso_w, 4, shirt)
	# Highlight on left column.
	for y in range(ty + 1, ty + 4):
		_px(img, torso_x, y, shirt_hi)
	# Shadow on right column.
	for y in range(ty + 1, ty + 4):
		_px(img, torso_x + torso_w - 1, y, shirt_shadow)

	# =================================================================
	# ARMS  (alongside torso, rows 8–12)
	# =================================================================
	var arm_hi := shirt.darkened(0.08)
	var arm_lo := shirt.darkened(0.22)

	match assignment:
		0, 2, 3:  # Typing motion.
			if pose == 0:
				for y in range(ty, ty + 4):
					_px(img, torso_x - 1, y, arm_hi)
					_px(img, torso_x + torso_w, y, arm_lo)
				# Hands at rest.
				_px(img, torso_x - 1, ty + 4, skin)
				_px(img, torso_x + torso_w, ty + 4, skin_shadow)
			else:
				for y in range(ty, ty + 3):
					_px(img, torso_x - 1, y, arm_hi)
					_px(img, torso_x + torso_w, y, arm_lo)
				# Hands forward (typing) — drawn on torso edge.
				_px(img, torso_x, ty + 3, skin)
				_px(img, torso_x + 1, ty + 3, skin)
				_px(img, torso_x + torso_w - 2, ty + 3, skin_shadow)
				_px(img, torso_x + torso_w - 1, ty + 3, skin_shadow)
		1:  # Bugs — scratching head on pose B.
			if pose == 0:
				for y in range(ty, ty + 4):
					_px(img, torso_x - 1, y, arm_hi)
					_px(img, torso_x + torso_w, y, arm_lo)
				_px(img, torso_x - 1, ty + 4, skin)
				_px(img, torso_x + torso_w, ty + 4, skin_shadow)
			else:
				# Left arm normal.
				for y in range(ty, ty + 4):
					_px(img, torso_x - 1, y, arm_hi)
				_px(img, torso_x - 1, ty + 4, skin)
				# Right arm up to head.
				_px(img, torso_x + torso_w, ty, arm_lo)
				_px(img, torso_x + torso_w, ty - 1, arm_lo)
				_px(img, torso_x + torso_w, ty - 2, skin_shadow)  # hand at hair
		4:  # R&D — hand on chin, pose B.
			if pose == 0:
				for y in range(ty, ty + 4):
					_px(img, torso_x - 1, y, arm_hi)
					_px(img, torso_x + torso_w, y, arm_lo)
				_px(img, torso_x - 1, ty + 4, skin)
				_px(img, torso_x + torso_w, ty + 4, skin_shadow)
			else:
				# Left arm normal.
				for y in range(ty, ty + 4):
					_px(img, torso_x - 1, y, arm_hi)
				_px(img, torso_x - 1, ty + 4, skin)
				# Right arm up, hand on chin.
				_px(img, torso_x + torso_w, ty, arm_lo)
				_px(img, torso_x + torso_w, ty - 1, arm_lo)
				_px(img, head_x + head_w - 1, 6, skin_shadow)  # hand on chin
		_:  # Unassigned — idle, arms at sides both poses.
			# Pose B: torso shifts down 1px for breathing bob.
			var arm_ty := ty + (1 if pose == 1 else 0)
			for y in range(arm_ty, arm_ty + 4):
				_px(img, torso_x - 1, y, arm_hi)
				_px(img, torso_x + torso_w, y, arm_lo)
			_px(img, torso_x - 1, arm_ty + 4, skin)
			_px(img, torso_x + torso_w, arm_ty + 4, skin_shadow)

	# Breathing bob for idle: shift torso down by 1 on pose B.
	if pose == 1 and assignment == 5:
		# Re-draw torso 1px lower (overwrite).
		_rect(img, torso_x, ty + 1, torso_w, 1, Color(0, 0, 0, 0))
		_rect(img, torso_x, ty + 2, torso_w, 4, shirt)
		_rect(img, torso_x, ty + 1, torso_w, 1, shirt_hi)  # collar shifts
		_px(img, cx - 1, ty + 1, shirt.lightened(0.25))
		_px(img, cx, ty + 1, shirt.lightened(0.25))

	# =================================================================
	# BELT  (row 13)
	# =================================================================
	_rect(img, torso_x, 13, torso_w, 1, BELT_COLOR)

	# =================================================================
	# LEGS  (rows 14–17: two 3px-wide legs with 2px gap)
	# =================================================================
	var leg_inner := cx - 1
	var leg_outer_l := torso_x + 1
	var leg_outer_r := torso_x + torso_w - 2
	for y in range(14, 18):
		# Left leg.
		_px(img, leg_outer_l, y, PANTS_COLOR)
		_px(img, leg_outer_l + 1, y, PANTS_COLOR)
		_px(img, leg_inner, y, PANTS_SHADOW)
		# Right leg.
		_px(img, leg_inner + 1, y, PANTS_SHADOW)
		_px(img, leg_outer_r - 1, y, PANTS_COLOR)
		_px(img, leg_outer_r, y, PANTS_COLOR)

	# =================================================================
	# SHOES  (rows 18–19)
	# =================================================================
	for y in range(18, 20):
		# Left shoe.
		_px(img, leg_outer_l, y, SHOE_COLOR)
		_px(img, leg_outer_l + 1, y, SHOE_COLOR)
		_px(img, leg_inner, y, SHOE_COLOR)
		# Right shoe.
		_px(img, leg_inner + 1, y, SHOE_COLOR)
		_px(img, leg_outer_r - 1, y, SHOE_COLOR)
		_px(img, leg_outer_r, y, SHOE_COLOR)
	# Shoe toe highlight.
	_px(img, leg_outer_l, 19, SHOE_COLOR.lightened(0.15))
	_px(img, leg_outer_r, 19, SHOE_COLOR.lightened(0.15))

	return img
