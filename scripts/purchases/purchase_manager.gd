extends Node
## Store service layer. Uses the platform's official billing plugin when present.
## No plugin => store is "unavailable" (no fake purchases). No server-side verification is claimed.

signal purchase_result(product: String, success: bool, message_key: String)
signal restore_result(count: int)

var config: Dictionary = {}
var plugin: Object = null
var backend: String = ""
var busy: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	config = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/monetization.json"))
	var pl: Dictionary = config["plugins"]
	if OS.get_name() == "Android" and Engine.has_singleton(str(pl["billing_singleton"])):
		plugin = Engine.get_singleton(str(pl["billing_singleton"]))
		backend = "google_play"
	elif OS.get_name() == "iOS" and Engine.has_singleton(str(pl["ios_iap_singleton"])):
		plugin = Engine.get_singleton(str(pl["ios_iap_singleton"]))
		backend = "app_store"

func is_available() -> bool:
	return plugin != null

func product_ids() -> Array:
	return (config["products"] as Dictionary).keys()

func purchase(product: String) -> void:
	if not is_available():
		purchase_result.emit(product, false, "store_unavailable")
		return
	if not (config["products"] as Dictionary).has(product):
		purchase_result.emit(product, false, "store_error")
		return
	busy = true
	if plugin.has_method("purchase"):
		plugin.call("purchase", [product])
	else:
		busy = false
		purchase_result.emit(product, false, "store_error")

func restore() -> void:
	if not is_available():
		restore_result.emit(0)
		return
	if plugin.has_method("queryPurchases"):
		plugin.call("queryPurchases", "inapp")

## Called by the billing plugin callbacks after the store confirmed a purchase.
func grant(product: String) -> void:
	busy = false
	match product:
		"frogpop_pro_monthly": ProgressionManager.set_pro(true, "monthly")
		"frogpop_pro_yearly": ProgressionManager.set_pro(true, "yearly")
		"frogpop_pro_lifetime": ProgressionManager.set_pro(true, "lifetime")
		"frogpop_remove_ads":
			SaveManager.data["remove_ads"] = true
			SaveManager.save()
		_:
			purchase_result.emit(product, false, "store_error")
			return
	purchase_result.emit(product, true, "purchase_ok")

func revoke_subscription() -> void:
	var k: String = str(SaveManager.data["pro"]["kind"])
	if k == "monthly" or k == "yearly":
		ProgressionManager.set_pro(false)
