extends ScreenBase

var status: LocLabel
var buttons: Array[FButton] = []

func _ready() -> void:
	build_base("pro_title", false)
	var hero := CenterContainer.new()
	var crown: TextureRect = UI.icon_rect("crown", 190)
	hero.add_child(crown)
	content.add_child(hero)
	var ct: Tween = crown.create_tween().set_loops()
	crown.pivot_offset = Vector2(95, 95)
	ct.tween_property(crown, "rotation", deg_to_rad(6), 0.9).set_trans(Tween.TRANS_SINE)
	ct.tween_property(crown, "rotation", deg_to_rad(-6), 0.9).set_trans(Tween.TRANS_SINE)
	if ProgressionManager.is_pro():
		var k: String = str(SaveManager.data["pro"]["kind"])
		content.add_child(UI.label("pro_active", 52, Color("7dffb0"), HORIZONTAL_ALIGNMENT_CENTER, [k]))
	var c: PanelContainer = card(300)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	c.add_child(v)
	v.add_child(UI.label("pro_benefits", 44, Color("ffd23c")))
	for k2 in ["pro_b1", "pro_b2", "pro_b3", "pro_b4", "pro_b5"]:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 14)
		var ck: TextureRect = UI.icon_rect("check", 44)
		ck.modulate = Color("7dffb0")
		h.add_child(ck)
		var l: LocLabel = UI.label(k2, 34, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		v.add_child(h)
	content.add_child(c)
	var avail: bool = PurchaseManager.is_available()
	if not avail:
		var na: LocLabel = UI.wrap_label("store_unavailable", 34, Color("ff9a9a"), 900)
		content.add_child(na)
	for pid in [["frogpop_pro_yearly", "pro_yearly", "yellow"], ["frogpop_pro_monthly", "pro_monthly", "blue"], ["frogpop_pro_lifetime", "pro_lifetime", "purple"], ["frogpop_remove_ads", "remove_ads", "gray"]]:
		var b: FButton = FButton.create(pid[1], pid[2], Vector2(900, 120), "crown" if pid[0] != "frogpop_remove_ads" else "ad", 44)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.disabled = not avail or ProgressionManager.is_pro()
		var product: String = pid[0]
		b.pressed.connect(func() -> void: PurchaseManager.purchase(product))
		content.add_child(b)
		buttons.append(b)
	var rb: FButton = FButton.create("pro_restore", "dark", Vector2(600, 100), "replay", 38)
	rb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rb.disabled = not avail
	rb.pressed.connect(func() -> void: PurchaseManager.restore())
	content.add_child(rb)
	content.add_child(UI.wrap_label("pro_note", 26, Color("8f9bd6"), 900))
	PurchaseManager.purchase_result.connect(_on_result)

func _on_result(_product: String, success: bool, msg_key: String) -> void:
	GameManager.toast(msg_key)
	if success:
		GameManager.go("pro")

func _exit_tree() -> void:
	if PurchaseManager.purchase_result.is_connected(_on_result):
		PurchaseManager.purchase_result.disconnect(_on_result)
