extends Node
## CSV driven localisation (key,en,tr,...). Add a column + a language entry to add a language.

signal language_changed(code: String)

const CSV_PATH: String = "res://localization/strings.csv"
var table: Dictionary = {}       # key -> {code: text}
var languages: Array[String] = []
var current: String = "en"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_table()
	var saved: String = str(SaveManager.data["settings"].get("language", ""))
	if saved == "":
		var loc: String = OS.get_locale_language()
		saved = "tr" if loc == "tr" else "en"
	set_language(saved, false)

func load_table() -> void:
	table.clear()
	languages.clear()
	var f: FileAccess = FileAccess.open(CSV_PATH, FileAccess.READ)
	if f == null:
		push_warning("localization csv missing")
		return
	var header: PackedStringArray = f.get_csv_line()
	for i in range(1, header.size()):
		languages.append(header[i])
	while not f.eof_reached():
		var row: PackedStringArray = f.get_csv_line()
		if row.size() < 2 or row[0] == "" or row[0].begins_with("#"):
			continue
		var entry: Dictionary = {}
		for i in range(1, mini(row.size(), header.size())):
			entry[header[i]] = row[i]
		table[row[0]] = entry

func set_language(code: String, persist: bool = true) -> void:
	if not languages.has(code):
		code = "en"
	current = code
	if persist:
		SaveManager.data["settings"]["language"] = code
		SaveManager.mark_dirty()
	TranslationServer.set_locale(code)
	language_changed.emit(code)

func t(key: String, args: Array = []) -> String:
	var entry: Dictionary = table.get(key, {})
	var txt: String = str(entry.get(current, ""))
	if txt == "":
		txt = str(entry.get("en", key))
	txt = txt.replace("\\n", "\n")
	if not args.is_empty():
		for i in args.size():
			txt = txt.replace("{%d}" % i, str(args[i]))
	return txt

func has_key(key: String) -> bool:
	return table.has(key)

func world_name(i: int) -> String:
	return t("world_%d" % i)

static func fmt_num(n: int) -> String:
	var s: String = str(absi(n))
	var out: String = ""
	var c: int = 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "." + out
	return ("-" if n < 0 else "") + out
