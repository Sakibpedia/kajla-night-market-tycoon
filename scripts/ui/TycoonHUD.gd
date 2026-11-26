extends CanvasLayer
## Night-market HUD: live business figures, stall management and day summary.

var market = null
var state: String = ""
var notice: String = ""
var notice_time: float = 0.0
var root: Control
var lbl_top: Label
var lbl_mid: Label
var lbl_bottom: Label
var lbl_notice: Label
var panel: Panel
var lbl_panel: Label
var mini = null
var bar_fill: ColorRect


func _ready() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var top_scrim := ColorRect.new()
	top_scrim.color = Color(0.02, 0.05, 0.05, 0.58)
	top_scrim.position = Vector2(0, 0)
	top_scrim.size = Vector2(1280, 132)
	root.add_child(top_scrim)
	var bottom_scrim := ColorRect.new()
	bottom_scrim.color = Color(0.02, 0.05, 0.05, 0.55)
	bottom_scrim.position = Vector2(0, 636)
	bottom_scrim.size = Vector2(1280, 84)
	root.add_child(bottom_scrim)
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.12, 0.22, 0.21, 0.85)
	bar_bg.position = Vector2(24, 136)
	bar_bg.size = Vector2(280, 8)
	root.add_child(bar_bg)
	bar_fill = ColorRect.new()
	bar_fill.color = Color(0.95, 0.74, 0.34)
	bar_fill.position = Vector2(24, 136)
	bar_fill.size = Vector2(0, 8)
	root.add_child(bar_fill)
	lbl_top = _label(Vector2(24, 18), Vector2(760, 38), 25, Color(0.97, 0.82, 0.48))
	lbl_mid = _label(Vector2(24, 58), Vector2(760, 34), 19, Color(0.62, 0.90, 0.82))
	lbl_bottom = _label(Vector2(24, 650), Vector2(900, 44), 18, Color(0.94, 0.94, 0.88))
	lbl_notice = _label(Vector2(300, 520), Vector2(680, 42), 21, Color(1.0, 0.86, 0.50))
	panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -330
	panel.offset_top = -220
	panel.offset_right = 330
	panel.offset_bottom = 220
	panel.visible = false
	root.add_child(panel)
	lbl_panel = Label.new()
	lbl_panel.position = Vector2(24, 18)
	lbl_panel.size = Vector2(612, 400)
	panel.add_child(lbl_panel)
	var credit := _label(Vector2(940, 690), Vector2(320, 22), 13, Color(0.58, 0.66, 0.64))
	credit.text = "© S M Nazmuz Sakib  •  OSM contributors (ODbL)"
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mini = MiniMap.new()
	mini.hud = self
	add_child(mini)


func _label(pos: Vector2, size: Vector2, fs: int, col: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = size
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	root.add_child(l)
	return l


func refresh() -> void:
	if market == null:
		return
	var d: Dictionary = market.data
	var mins := int(market.time_left) / 60
	var secs := int(market.time_left) % 60
	lbl_top.text = "রাত %d/15 — %s   |   ৳ %d   |   আজকের লাভ ৳ %d" % [
		Game.day, str(d.get("event", "")), Game.wallet, market.profit]
	lbl_mid.text = "সময় %02d:%02d   •   ক্রেতা %d/%d   •   সুনাম %d (%+d)   •   ভাড়া ৳%d   •   %s" % [
		mins, secs, market.served, int(d.get("target_customers", 0)),
		Game.reputation, market.rep_change, int(d.get("rent", 0)), Game.rank()]
	lbl_bottom.text = "লক্ষ্য: ৳ %d লাভ  •  %d ক্রেতা   |   WASD চলুন   E দোকান   F দিন শেষ   ESC বিরতি" % [
		int(d.get("target_profit", 0)), int(d.get("target_customers", 0))]
	lbl_notice.text = notice if notice_time > 0.0 else ""
	var target: int = maxi(1, int(d.get("target_profit", 1)))
	bar_fill.size.x = clampf(float(market.profit) / float(target), 0.0, 1.0) * 280.0
	mini.queue_redraw()


func tick(delta: float) -> void:
	notice_time = maxf(0.0, notice_time - delta)


func notify(text: String) -> void:
	notice = text
	notice_time = 4.0


func blocking() -> bool:
	return state != ""


func close_panel() -> void:
	if state == "stall":
		state = ""
		panel.visible = false


func open_stall(idx: int) -> void:
	state = "stall"
	_refresh_panel()


func _refresh_panel() -> void:
	panel.visible = state != ""
	if state == "stall":
		var i: int = market.selected
		var price := Game.price_of(i)
		var fair := Game.fair_price(i)
		lbl_panel.text = "দোকান %02d — %s (%s)\n\n" % [i + 1, Game.stall_name(i), Game.stall_kind(i)]
		lbl_panel.text += "স্টক %d/%d   •   দাম ৳%d (উচিত ৳%d)\n" % [
			Game.stock_of(i), Game.capacity(i), price, fair]
		lbl_panel.text += "কর্মচারী %d   •   উন্নত স্তর %d\n\n" % [
			Game.staff_count(i), Game.stall_level(i)]
		lbl_panel.text += "1  স্টক +10 কিনুন (৳%d)\n" % [int(Game.WHOLESALE.get(Game.stall_kind(i), 15)) * 10]
		lbl_panel.text += "2  দাম +5    3  দাম -5\n4  কর্মচারী নিয়োগ (৳180)\n5  দোকান উন্নতি (৳%d)\n\n[E/ESC] বন্ধ করুন" % [
			250 * (Game.stall_level(i) + 1)]
	elif state == "summary":
		pass


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	var k: int = event.keycode
	if state == "stall":
		var i: int = market.selected
		if k == KEY_1:
			Game.buy_stock(i, 10)
			notify("স্টক কেনা হয়েছে")
		elif k == KEY_2:
			Game.set_price(i, Game.price_of(i) + 5)
		elif k == KEY_3:
			Game.set_price(i, Game.price_of(i) - 5)
		elif k == KEY_4:
			Game.hire_staff(i)
			notify("কর্মচারী যোগ দিয়েছেন")
		elif k == KEY_5:
			Game.upgrade_stall(i)
			notify("দোকান উন্নত হয়েছে")
		_refresh_panel()
		if k == KEY_E or k == KEY_ESCAPE:
			close_panel()
	elif state == "summary":
		if k == KEY_M:
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		elif k == KEY_R:
			market.reset_for_retry()
		elif k == KEY_N and bool(Game.last_result.get("success", false)):
			market.next_day()


func show_summary(success: bool, profit: int, customers: int, rep: int, rent: int) -> void:
	state = "summary"
	panel.visible = true
	var r: Dictionary = Game.last_result
	lbl_panel.text = ("দিন শেষ — সফল" if success else "দিন শেষ — ব্যর্থ") + "\n\n"
	lbl_panel.text += "লাভ ৳%d   ভাড়া ৳%d   ক্রেতা %d   সুনাম %+d\n" % [profit, rent, customers, rep]
	if success:
		lbl_panel.text += "গ্রেড %s   •   নতুন ব্যালেন্স ৳%d\n\n" % [str(r.get("grade", "C")), Game.wallet]
		lbl_panel.text += "[N] পরবর্তী রাত   [R] আবার   [M] মেনু"
	else:
		lbl_panel.text += "\n[R] আবার চেষ্টা   [M] মেনু"


class MiniMap extends Node2D:
	var hud

	func _draw() -> void:
		if hud == null or hud.market == null:
			return
		var m = hud.market
		var c = m.city
		var center: Vector2 = m.hero.position
		var sc := 0.05
		var size := 210.0
		draw_rect(Rect2(1040, 18, size, size), Color(0.03, 0.08, 0.07, 0.88))
		draw_rect(Rect2(1040, 18, size, size), Color(0.86, 0.70, 0.38), false, 2.0)
		for b in c.render_buildings:
			var r: Rect2 = b["rect"]
			var rp := Rect2(Vector2(1040, 18) + (r.position - center) * sc + Vector2(size / 2.0, size / 2.0), r.size * sc)
			if rp.intersects(Rect2(1040, 18, size, size)):
				draw_rect(rp, Color(0.40, 0.36, 0.30, 0.85))
		for s in m.stalls:
			var p: Vector2 = s["pos"]
			var mp := Vector2(1040, 18) + (p - center) * sc + Vector2(size / 2.0, size / 2.0)
			if mp.x > 1040 and mp.x < 1040 + size and mp.y > 18 and mp.y < 18 + size:
				draw_circle(mp, 3.0, Color(1.0, 0.80, 0.35))
		draw_circle(Vector2(1040 + size / 2.0, 18 + size / 2.0), 4.0, Color(0.30, 0.90, 0.80))
