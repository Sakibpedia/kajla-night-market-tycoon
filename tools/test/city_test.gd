extends Node
## Headless city verification for the top-down OSM colony.
var city
var t := 0.0
var reported := false

func _ready() -> void:
	city = load("res://scripts/world/City2D.gd").new()
	add_child(city)

func _process(delta: float) -> void:
	t += delta
	if t < 1.0 or reported:
		return
	reported = true
	var nb: int = city.buildings.size()
	var nr: int = city.roads.size()
	var ns: int = city.shops.size()
	var ng: int = city.gates.size()
	var np: int = city.road_points.size()
	var npl: int = city.plaza_stalls.size()
	var ok: bool = nb >= 1400 and nr >= 200 and ns == 30 and ng == 15 and np >= 80 and npl >= 12
	print("[CITY2D] buildings=%d roads=%d shops=%d plaza_stalls=%d gates=%d points=%d" % [nb, nr, ns, npl, ng, np])
	print("[CITY2D] %s" % ("PASS" if ok else "FAIL"))
	get_tree().quit(0 if ok else 1)
