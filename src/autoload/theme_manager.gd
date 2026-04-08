extends Node
## ThemeManager — global Venture dark theme.
##
## Applied once at startup via get_tree().root.theme so every Control inherits it.
## Per-node theme_override_* properties in .tscn files still take precedence,
## giving scene designers full control to diverge where needed.
##
## Usage from other scripts:
##   var c := ThemeManager.C_GOLD           # palette constant
##   var col := ThemeManager.health_color(0.72)  # green/gold/red by ratio


# ---------------------------------------------------------------------------
# Palette — single source of truth for all colors in the game.
# Harmonized with the existing dark-navy base the scenes already use.
# ---------------------------------------------------------------------------

## Background & surfaces
const C_BG          := Color(0.070, 0.090, 0.130, 1.0)  # #12172 — deep navy
const C_SURFACE     := Color(0.110, 0.135, 0.185, 1.0)  # #1C2230 — card surface
const C_SURFACE_LOW := Color(0.080, 0.100, 0.145, 1.0)  # #141A25 — sunken surface
const C_SURFACE_HIGH:= Color(0.145, 0.175, 0.235, 1.0)  # #252C3C — raised surface

## Borders
const C_BORDER      := Color(0.200, 0.260, 0.360, 1.0)  # #33425C — subtle
const C_BORDER_FOCUS:= Color(0.290, 0.620, 1.000, 1.0)  # #4A9EFF — active/focus

## Accent colours — used for highlights, badges, health indicators
const C_BLUE        := Color(0.290, 0.620, 1.000, 1.0)  # #4A9EFF — primary action
const C_GREEN       := Color(0.300, 0.850, 0.450, 1.0)  # #4DD972 — positive / earn
const C_RED         := Color(0.878, 0.322, 0.322, 1.0)  # #E05252 — danger / burn
const C_GOLD        := Color(0.960, 0.740, 0.310, 1.0)  # #F5BD4F — money / warning
const C_PURPLE      := Color(0.608, 0.447, 0.812, 1.0)  # #9B72CF — valuation / special
const C_TEAL        := Color(0.220, 0.780, 0.720, 1.0)  # #38C7B8 — info / market

## Text
const C_TEXT        := Color(0.950, 0.950, 0.970, 1.0)  # #F2F2F8 — primary text
const C_TEXT_DIM    := Color(0.620, 0.660, 0.740, 1.0)  # #9EA9BD — secondary
const C_TEXT_MUTED  := Color(0.350, 0.390, 0.470, 1.0)  # #596378 — very muted
const C_TEXT_HINT   := Color(0.580, 0.740, 0.920, 1.0)  # #94BDEB — info hint blue

## Specials
const C_CHIP        := Color(0.957, 0.784, 0.259, 1.0)  # #F4C842 — VC Chip gold
const C_ORANGE      := Color(0.950, 0.550, 0.400, 1.0)  # #F28C66 — stress / warm accent
const C_TRANSPARENT := Color(0.0, 0.0, 0.0, 0.0)
const C_OVERLAY     := Color(0.020, 0.050, 0.120, 0.92) # modal backdrop

# ---------------------------------------------------------------------------
# Shape / spacing constants
# ---------------------------------------------------------------------------
const CORNER_XS := 2
const CORNER_SM := 4
const CORNER_MD := 8
const CORNER_LG := 12
const CORNER_XL := 18

const BORDER_W  := 1

## Apple HIG minimum touch target: 44pt. We use 46 for safety.
const TOUCH_MIN_H := 46

# ---------------------------------------------------------------------------
# Font sizes — readable at 720×1280 on an iPhone SE (2x display)
# ---------------------------------------------------------------------------
const FONT_XS   := 11
const FONT_SM   := 13
const FONT_MD   := 15   # default body
const FONT_LG   := 18
const FONT_XL   := 22
const FONT_ICON := 24   # icon text / large badges
const FONT_XXL  := 28
const FONT_HERO := 36
const FONT_JUMBO:= 48   # splash / game over numbers


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	# Defer so all autoloads + main scene nodes exist before we set the theme,
	# allowing Controls to pick it up during their own _ready() propagation.
	call_deferred("_apply_global_theme")


func _apply_global_theme() -> void:
	if get_tree() == null:
		return
	get_tree().root.theme = _build_theme()


# ---------------------------------------------------------------------------
# Public helpers — callable from any .gd file via ThemeManager.*
# ---------------------------------------------------------------------------

## Returns the top safe area inset in viewport pixels (for notched devices).
## On desktop or non-notched devices, returns 0. Use this to pad screen tops
## so content doesn't clip under the status bar or camera notch.
static func safe_inset_top() -> float:
	if not _is_mobile_platform():
		return 0.0
	var screen_w := float(DisplayServer.screen_get_size().x)
	if screen_w <= 0.0:
		return 0.0
	var safe := DisplayServer.screen_get_usable_rect()
	# With canvas_items + expand, viewport width is locked at 720;
	# physical→viewport scale factor is 720 / physical_screen_width.
	return maxf(0.0, float(safe.position.y) * (720.0 / screen_w))


## Returns the bottom safe area inset in viewport pixels (for home indicator).
static func safe_inset_bottom() -> float:
	if not _is_mobile_platform():
		return 0.0
	var screen := DisplayServer.screen_get_size()
	var screen_w := float(screen.x)
	var screen_h := float(screen.y)
	if screen_w <= 0.0 or screen_h <= 0.0:
		return 0.0
	var safe := DisplayServer.screen_get_usable_rect()
	var bottom_physical := screen_h - float(safe.position.y + safe.size.y)
	return maxf(0.0, bottom_physical * (720.0 / screen_w))


## Convenience: returns the top margin a screen should use, ensuring it's
## at least the safe inset. Pass the screen's designed minimum margin.
static func safe_top_margin(designed_margin: float = 40.0) -> float:
	return maxf(designed_margin, safe_inset_top())


## Convenience: returns the bottom margin a screen should use.
static func safe_bottom_margin(designed_margin: float = 24.0) -> float:
	return maxf(designed_margin, safe_inset_bottom())


static func _is_mobile_platform() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("ios") or OS.has_feature("android")


## Returns green / gold / red based on a 0.0-1.0 health ratio.
## inverted=true means 0.0 is good (used for tech_debt, bugs).
static func health_color(ratio: float, inverted: bool = false) -> Color:
	var h := clampf(ratio if not inverted else (1.0 - ratio), 0.0, 1.0)
	if h >= 0.65:
		return C_GREEN
	elif h >= 0.35:
		return C_GOLD
	return C_RED


## Returns a StyleBoxFlat card with morale-based left border (3 px).
static func morale_card_style(morale: int) -> StyleBoxFlat:
	var s := _flat_box_static(C_SURFACE, C_BORDER, CORNER_MD)
	var m_color := health_color(morale / 100.0)
	s.border_color = C_BORDER
	s.set_border_width_all(0)
	s.border_width_left = 3
	s.border_color = m_color
	return s


## Creates a filled pill badge StyleBoxFlat (used for assignment / status badges).
static func badge_style(bg: Color, corner: int = CORNER_XL) -> StyleBoxFlat:
	return _flat_box_static(bg, C_TRANSPARENT, corner, 0)


## Tints a ProgressBar's fill according to value / max (or inverted for cost metrics).
static func tint_bar(bar: ProgressBar, val: float, max_val: float = 100.0,
		inverted: bool = false) -> void:
	var ratio := clampf(val / maxf(1.0, max_val), 0.0, 1.0)
	var fill_color := health_color(ratio, inverted)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(CORNER_SM)
	bar.add_theme_stylebox_override("fill", fill)


# ---------------------------------------------------------------------------
# Theme construction
# ---------------------------------------------------------------------------
func _build_theme() -> Theme:
	var t := Theme.new()

	# Default font size used when no override is set
	t.default_font_size = FONT_MD

	_apply_button(t)
	_apply_label(t)
	_apply_rich_text_label(t)
	_apply_panel(t)
	_apply_progress_bar(t)
	_apply_line_edit(t)
	_apply_scroll(t)
	_apply_tab_bar(t)
	_apply_popup(t)
	_apply_option_button(t)
	_apply_separators(t)
	_apply_check_box(t)

	return t


func _apply_button(t: Theme) -> void:
	# Normal: subtle panel surface
	var normal  := _btn(C_SURFACE,      C_BORDER,       CORNER_MD)
	# Hover: accent-tinted, brighter border
	var hover   := _btn(Color(0.12, 0.22, 0.38, 1.0), C_BLUE, CORNER_MD)
	# Pressed: deeper accent
	var pressed := _btn(Color(0.09, 0.17, 0.30, 1.0), C_BORDER_FOCUS, CORNER_MD)
	# Disabled: de-saturated, no border
	var disabled:= _btn(C_SURFACE_LOW,  C_BORDER,       CORNER_MD)
	# Focus ring: accent outline only
	var focus   := _btn(C_SURFACE,      C_BLUE,         CORNER_MD)
	focus.set_border_width_all(2)

	t.set_stylebox("normal",   "Button", normal)
	t.set_stylebox("hover",    "Button", hover)
	t.set_stylebox("pressed",  "Button", pressed)
	t.set_stylebox("disabled", "Button", disabled)
	t.set_stylebox("focus",    "Button", focus)

	t.set_color("font_color",          "Button", C_TEXT)
	t.set_color("font_hover_color",    "Button", Color.WHITE)
	t.set_color("font_pressed_color",  "Button", C_BLUE)
	t.set_color("font_disabled_color", "Button", C_TEXT_MUTED)
	t.set_color("font_focus_color",    "Button", C_TEXT)
	t.set_color("icon_normal_color",   "Button", C_TEXT)
	t.set_color("icon_hover_color",    "Button", Color.WHITE)
	t.set_color("icon_disabled_color", "Button", C_TEXT_MUTED)

	t.set_font_size("font_size", "Button", FONT_MD)
	t.set_constant("h_separation", "Button", 6)


func _apply_label(t: Theme) -> void:
	t.set_color("font_color",        "Label", C_TEXT)
	t.set_color("font_shadow_color", "Label", Color(0.0, 0.0, 0.0, 0.35))
	t.set_font_size("font_size",     "Label", FONT_MD)
	t.set_constant("shadow_offset_x", "Label", 0)
	t.set_constant("shadow_offset_y", "Label", 1)
	t.set_constant("outline_size",    "Label", 0)


func _apply_rich_text_label(t: Theme) -> void:
	t.set_color("default_color", "RichTextLabel", C_TEXT)
	t.set_color("font_shadow_color", "RichTextLabel", Color(0, 0, 0, 0.3))
	t.set_font_size("normal_font_size", "RichTextLabel", FONT_MD)
	t.set_stylebox("normal", "RichTextLabel", StyleBoxEmpty.new())
	t.set_stylebox("focus",  "RichTextLabel", StyleBoxEmpty.new())


func _apply_panel(t: Theme) -> void:
	var panel_style := _flat(C_SURFACE, C_BORDER, CORNER_MD)
	t.set_stylebox("panel", "PanelContainer", panel_style)
	t.set_stylebox("panel", "Panel", panel_style)


func _apply_progress_bar(t: Theme) -> void:
	var bg   := _flat(C_SURFACE_LOW, C_BORDER, CORNER_SM)
	var fill := _flat(C_BLUE, C_TRANSPARENT, CORNER_SM, 0)
	t.set_stylebox("background", "ProgressBar", bg)
	t.set_stylebox("fill",       "ProgressBar", fill)
	t.set_color("font_color", "ProgressBar", C_TEXT)
	t.set_font_size("font_size", "ProgressBar", FONT_SM)


func _apply_line_edit(t: Theme) -> void:
	var normal    := _flat(C_SURFACE_LOW, C_BORDER,       CORNER_SM)
	var focus_box := _flat(C_SURFACE_LOW, C_BORDER_FOCUS, CORNER_SM)
	var read_only := _flat(Color(0.06, 0.08, 0.12, 1.0), C_TRANSPARENT, CORNER_SM)
	focus_box.set_border_width_all(2)

	t.set_stylebox("normal",    "LineEdit", normal)
	t.set_stylebox("focus",     "LineEdit", focus_box)
	t.set_stylebox("read_only", "LineEdit", read_only)

	t.set_color("font_color",             "LineEdit", C_TEXT)
	t.set_color("font_placeholder_color", "LineEdit", C_TEXT_MUTED)
	t.set_color("font_selected_color",    "LineEdit", Color.WHITE)
	t.set_color("selection_color",        "LineEdit", Color(0.29, 0.62, 1.0, 0.35))
	t.set_color("caret_color",            "LineEdit", C_BLUE)
	t.set_font_size("font_size", "LineEdit", FONT_MD)


func _apply_scroll(t: Theme) -> void:
	var track    := _flat(C_SURFACE_LOW,  C_TRANSPARENT, CORNER_SM, 0)
	var grabber  := _flat(C_BORDER,       C_TRANSPARENT, CORNER_SM, 0)
	var grabber_hi  := _flat(C_TEXT_MUTED,  C_TRANSPARENT, CORNER_SM, 0)
	var grabber_pr  := _flat(C_BLUE.darkened(0.35), C_TRANSPARENT, CORNER_SM, 0)

	for bar_type in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll",            bar_type, track)
		t.set_stylebox("scroll_focus",      bar_type, track)
		t.set_stylebox("grabber",           bar_type, grabber)
		t.set_stylebox("grabber_highlight", bar_type, grabber_hi)
		t.set_stylebox("grabber_pressed",   bar_type, grabber_pr)

	t.set_constant("width", "VScrollBar", 4)
	t.set_constant("width", "HScrollBar", 4)
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())


func _apply_tab_bar(t: Theme) -> void:
	var sel   := _flat(Color(0.12, 0.22, 0.38, 1.0), C_BLUE,   CORNER_SM)
	var unsel := _flat(C_SURFACE_LOW,                  C_BORDER, 0)
	var hov   := _flat(C_SURFACE,                      C_BORDER, 0)
	var panel := _flat(C_SURFACE,                      C_BORDER, CORNER_MD)
	var tabbg := _flat(C_SURFACE_LOW,                  C_BORDER, 0)

	t.set_stylebox("panel",            "TabContainer", panel)
	t.set_stylebox("tabbar_background","TabContainer", tabbg)
	t.set_stylebox("tab_selected",     "TabBar", sel)
	t.set_stylebox("tab_unselected",   "TabBar", unsel)
	t.set_stylebox("tab_hovered",      "TabBar", hov)
	t.set_stylebox("tab_focus",        "TabBar", sel)

	t.set_color("font_selected_color",   "TabBar", C_TEXT)
	t.set_color("font_unselected_color", "TabBar", C_TEXT_DIM)
	t.set_color("font_hovered_color",    "TabBar", C_TEXT)
	t.set_font_size("font_size", "TabBar", FONT_SM)


func _apply_popup(t: Theme) -> void:
	var popup_panel := _flat(C_SURFACE, C_BORDER_FOCUS, CORNER_LG)
	popup_panel.set_border_width_all(2)
	t.set_stylebox("panel", "PopupPanel", popup_panel)

	# PopupMenu (used by OptionButton dropdown)
	var pm_panel := _flat(C_SURFACE, C_BORDER, CORNER_MD)
	var pm_hover := _flat(Color(0.12, 0.22, 0.38, 1.0), C_TRANSPARENT, CORNER_SM, 0)
	t.set_stylebox("panel",     "PopupMenu", pm_panel)
	t.set_stylebox("hover",     "PopupMenu", pm_hover)
	t.set_stylebox("separator", "PopupMenu", StyleBoxLine.new())

	t.set_color("font_color",          "PopupMenu", C_TEXT)
	t.set_color("font_hover_color",    "PopupMenu", Color.WHITE)
	t.set_color("font_disabled_color", "PopupMenu", C_TEXT_MUTED)
	t.set_color("font_separator_color","PopupMenu", C_TEXT_MUTED)
	t.set_font_size("font_size", "PopupMenu", FONT_MD)
	t.set_constant("v_separation", "PopupMenu", 8)
	t.set_constant("h_separation", "PopupMenu", 10)


func _apply_option_button(t: Theme) -> void:
	t.set_stylebox("normal",   "OptionButton", _btn(C_SURFACE, C_BORDER, CORNER_MD))
	t.set_stylebox("hover",    "OptionButton", _btn(Color(0.12, 0.22, 0.38, 1.0), C_BLUE, CORNER_MD))
	t.set_stylebox("pressed",  "OptionButton", _btn(Color(0.09, 0.17, 0.30, 1.0), C_BORDER_FOCUS, CORNER_MD))
	t.set_stylebox("disabled", "OptionButton", _btn(C_SURFACE_LOW, C_BORDER, CORNER_MD))
	t.set_stylebox("focus",    "OptionButton", _btn(C_SURFACE, C_BLUE, CORNER_MD))

	t.set_color("font_color",          "OptionButton", C_TEXT)
	t.set_color("font_hover_color",    "OptionButton", Color.WHITE)
	t.set_color("font_pressed_color",  "OptionButton", C_BLUE)
	t.set_color("font_disabled_color", "OptionButton", C_TEXT_MUTED)
	t.set_font_size("font_size", "OptionButton", FONT_MD)


func _apply_separators(t: Theme) -> void:
	var line := StyleBoxLine.new()
	line.color = C_BORDER
	line.thickness = 1
	t.set_stylebox("separator", "HSeparator", line)
	t.set_stylebox("separator", "VSeparator", line)
	t.set_constant("separation", "HSeparator", 1)
	t.set_constant("separation", "VSeparator", 1)


func _apply_check_box(t: Theme) -> void:
	t.set_color("font_color",       "CheckBox", C_TEXT)
	t.set_color("font_hover_color", "CheckBox", C_TEXT)
	t.set_font_size("font_size",    "CheckBox", FONT_MD)


# ---------------------------------------------------------------------------
# StyleBoxFlat factory helpers (instance methods for _build_theme)
# ---------------------------------------------------------------------------
func _flat(bg: Color, border: Color, corner: int,
		border_w: int = BORDER_W) -> StyleBoxFlat:
	return ThemeManager._flat_box_static(bg, border, corner, border_w)


func _btn(bg: Color, border: Color, corner: int) -> StyleBoxFlat:
	var s := _flat(bg, border, corner)
	# Touch-friendly padding — Apple HIG 44pt minimum height
	s.content_margin_left   = 16.0
	s.content_margin_right  = 16.0
	s.content_margin_top    = 13.0
	s.content_margin_bottom = 13.0
	return s


# ---------------------------------------------------------------------------
# Static factory — used by static helpers above (morale_card_style, badge_style)
# ---------------------------------------------------------------------------
static func _flat_box_static(bg: Color, border: Color, corner: int,
		border_w: int = BORDER_W) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(corner)
	s.anti_aliased = true
	s.aa_size = 0.5
	return s
