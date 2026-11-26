extends Node
## Global state for Kajla Night Market Tycoon: 15 business nights, stall data,
## wallet, reputation, staff, upgrades and persistent saves.

signal state_changed

const DAY_COUNT := 15
const SAVE_PATH := "user://kajla_night_market.cfg"
const STALL_KINDS := ["pharmacy", "clinic", "arms", "grocery", "general",
	"mobile", "tea", "hardware"]
const KIND_BN := {
	"pharmacy": "ফার্মাসি", "clinic": "ক্লিনিক", "arms": "অস্ত্র", "grocery": "গ্রোসারি",
	"general": "জেনারেল স্টোর", "mobile": "মোবাইল", "tea": "চায়ের দোকান", "hardware": "হার্ডওয়্যার"
}
const BASE_PRICE := {"pharmacy": 45, "clinic": 60, "arms": 120, "grocery": 25,
	"general": 30, "mobile": 90, "tea": 15, "hardware": 55}
const WHOLESALE := {"pharmacy": 22, "clinic": 30, "arms": 65, "grocery": 11,
	"general": 14, "mobile": 48, "tea": 6, "hardware": 27}
const DAY_NAMES := [
	"Proud Opening", "Tea Stall Wars", "Pharmacy Rush", "Mobile Mania",
	"Arms Dealer Audit", "Clinic Night", "Hardware Boom", "Grocery Festival",
	"Inspector's Visit", "Rival Market", "Water Shortage", "Festival Eve",
	"Big Discount Day", "Supplier Strike", "Market Empire"
]

var day: int = 1
var unlocked: int = 1
var wallet: int = 800
var reputation: int = 50
var stocks: Dictionary = {}      # str(idx) -> int
var prices: Dictionary = {}      # str(idx) -> int
var staff: Dictionary = {}       # str(idx) -> int
var levels: Dictionary = {}      # str(idx) -> int
var records: Dictionary = {}
var settings: Dictionary = {"sfx": true, "hints": true}
var last_result: Dictionary = {}


func _ready() -> void:
	load_game()


func stall_kind(idx: int) -> String:
	return STALL_KINDS[idx % STALL_KINDS.size()]


func stall_name(idx: int) -> String:
	return str(KIND_BN.get(stall_kind(idx), "দোকান"))


func fair_price(idx: int) -> int:
	return int(BASE_PRICE.get(stall_kind(idx), 30))


func price_of(idx: int) -> int:
	return int(prices.get(str(idx), fair_price(idx)))


func set_price(idx: int, p: int) -> void:
	prices[str(idx)] = clampi(p, 1, 999)
	save_game()
	state_changed.emit()


func stock_of(idx: int) -> int:
	return int(stocks.get(str(idx), 18))


func capacity(idx: int) -> int:
	return 18 + int(levels.get(str(idx), 0)) * 12


func buy_stock(idx: int, qty: int = 10) -> bool:
	var cost: int = int(WHOLESALE.get(stall_kind(idx), 15)) * qty
	if not spend(cost):
		return false
	stocks[str(idx)] = mini(stock_of(idx) + qty, capacity(idx))
	save_game()
	state_changed.emit()
	return true


func hire_staff(idx: int) -> bool:
	if not spend(180):
		return false
	staff[str(idx)] = int(staff.get(str(idx), 0)) + 1
	save_game()
	state_changed.emit()
	return true


func upgrade_stall(idx: int) -> bool:
	var lv: int = int(levels.get(str(idx), 0))
	var cost: int = 250 * (lv + 1)
	if lv >= 3 or not spend(cost):
		return false
	levels[str(idx)] = lv + 1
	save_game()
	state_changed.emit()
	return true


func staff_count(idx: int) -> int:
	return int(staff.get(str(idx), 0))


func stall_level(idx: int) -> int:
	return int(levels.get(str(idx), 0))


func day_data(idx: int) -> Dictionary:
	var i: int = clampi(idx, 1, DAY_COUNT) - 1
	return {
		"index": i + 1,
		"name": DAY_NAMES[i],
		"target_profit": 250 + i * 110,
		"target_customers": 8 + i * 2,
		"rent": 80 + i * 20,
		"rush": 1.0 + (i % 4) * 0.25,
		"event": ["সাধারণ রাত", "চা-স্টল প্রতিযোগিতা", "ফার্মাসি রাশ", "মোবাইল ক্রেজ", "পরিদর্শকের সফর", "প্রতিদ্বন্দ্বী বাজার", "সরবরাহ সংকট"][i % 7],
	}


func complete_day(idx: int, profit: int, customers: int, rep_delta: int) -> void:
	var d := day_data(idx)
	wallet += profit - int(d.get("rent", 0))
	reputation = clampi(reputation + rep_delta, 0, 100)
	var grade := "C"
	if profit >= int(d.get("target_profit", 0)) * 1.5: grade = "A"
	elif profit >= int(d.get("target_profit", 0)): grade = "B"
	records[str(idx)] = {"profit": profit, "customers": customers, "grade": grade}
	if idx >= unlocked and idx < DAY_COUNT:
		unlocked = idx + 1
	day = clampi(idx + 1, 1, DAY_COUNT)
	last_result = {"success": true, "profit": profit, "customers": customers,
		"grade": grade, "rent": int(d.get("rent", 0))}
	save_game()
	state_changed.emit()


func fail_day(idx: int, reason: String) -> void:
	last_result = {"success": false, "reason": reason}
	state_changed.emit()


func total_profit() -> int:
	var t := 0
	for r in records.values():
		t += int((r as Dictionary).get("profit", 0))
	return t


func rank() -> String:
	var p := total_profit()
	if p >= 30000: return "Market Baron"
	if p >= 18000: return "Tycoon"
	if p >= 9000: return "Shopkeeper"
	return "New Vendor"


func spend(cost: int) -> bool:
	if wallet < cost:
		return false
	wallet -= cost
	save_game()
	state_changed.emit()
	return true


func earn(amount: int) -> void:
	wallet += amount
	save_game()
	state_changed.emit()


func save_game() -> void:
	var cf := ConfigFile.new()
	cf.set_value("progress", "day", day)
	cf.set_value("progress", "unlocked", unlocked)
	cf.set_value("progress", "records", records)
	cf.set_value("business", "wallet", wallet)
	cf.set_value("business", "reputation", reputation)
	cf.set_value("business", "stocks", stocks)
	cf.set_value("business", "prices", prices)
	cf.set_value("business", "staff", staff)
	cf.set_value("business", "levels", levels)
	cf.set_value("settings", "values", settings)
	cf.save(SAVE_PATH)


func load_game() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) != OK:
		return
	day = clampi(int(cf.get_value("progress", "day", 1)), 1, DAY_COUNT)
	unlocked = clampi(int(cf.get_value("progress", "unlocked", 1)), 1, DAY_COUNT)
	records = cf.get_value("progress", "records", {})
	wallet = int(cf.get_value("business", "wallet", 800))
	reputation = int(cf.get_value("business", "reputation", 50))
	stocks = cf.get_value("business", "stocks", {})
	prices = cf.get_value("business", "prices", {})
	staff = cf.get_value("business", "staff", {})
	levels = cf.get_value("business", "levels", {})
	settings = cf.get_value("settings", "values", settings)
