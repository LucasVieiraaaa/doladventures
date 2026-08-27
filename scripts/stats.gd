extends Resource
class_name Stats

enum BuffableStats{
	MAX_HEALTH,
	DEFENSE,
	ATTACK
}

const STAT_CURVES: Dictionary[BuffableStats, Curve] = {
	BuffableStats.MAX_HEALTH: preload("uid://dalql5phqklo8"),
	BuffableStats.DEFENSE: preload("uid://c2y1cw8qv34yf"),
	BuffableStats.ATTACK: preload("uid://bj2cggforlgql")
}

const BASE_LEVEL_XP: float = 100.0

signal health_depleated
signal health_changed(cur_health: int, max_health: int)

@export var base_max_health: int = 100
@export var base_defense: int = 10
@export var base_attack: int = 10
@export var experience: int = 0: set = _on_experience_set

var level: int:
	get(): return floor(max(1.0, sqrt(experience/25.0) + 0.5))
var current_max_health: int = 100
var current_defense: int = 10
var current_attack: int = 10

var health: int = 0: set = _on_health_set

var stat_buffs: Array[StatBuff]

func _init () -> void:
	setup_stats.call_deferred()
	
func setup_stats() -> void:
	recalculate_stats()
	health = current_max_health
	
func add_buff(buff: StatBuff) -> void:
	stat_buffs.append(buff)
	recalculate_stats.call_deferred()
	
func remove_buff(buff: StatBuff)-> void:
	stat_buffs.append(buff)
	recalculate_stats.call_deferred()

func recalculate_stats()-> void:
	var stat_multipliers: Dictionary = {}
	var stat_addends: Dictionary = {}
	for buff in stat_buffs:
		var stat_name: String = BuffableStats.keys()[buff.stat].to_lower()
		match buff.buff_type:
			StatBuff.BuffType.ADD:
				if not stat_addends.has(stat_name):
					stat_addends[stat_name] = 0.0
				stat_addends[stat_name] += buff.buff_amount
			StatBuff.BuffType.MULTIPLY:
				if not stat_multipliers.has(stat_name):
					stat_multipliers[stat_name] = 1.0
				stat_multipliers[stat_name] += buff.buff_amount
				
				if stat_multipliers[stat_name] < 0.0:
					stat_multipliers[stat_name] = 0.0
	
	
	var stat_sample_pos: float = (float(level)/ 100.0) - 0.01
	current_max_health = base_max_health * STAT_CURVES[BuffableStats.MAX_HEALTH].sample(stat_sample_pos)
	current_defense = base_defense * STAT_CURVES[BuffableStats.DEFENSE].sample(stat_sample_pos)
	current_attack = base_attack * STAT_CURVES[BuffableStats.ATTACK].sample(stat_sample_pos)

	for stat_name in stat_multipliers:
		var cur_property_name: String = ("current_"+ stat_name)
		set(cur_property_name, get(cur_property_name) * stat_multipliers[stat_name])

	for stat_name in stat_addends:
		var cur_property_name: String = ("current_"+ stat_name)
		set(cur_property_name, get(cur_property_name) + stat_multipliers[stat_name])




func _on_health_set(new_value: int) -> void:
	health = clampi(new_value, 0, current_max_health)
	health_changed.emit(health, current_max_health)
	if health <= 0:
		health_depleated.emit()

func _on_experience_set(new_value: int)-> void:
	var old_level: int = level
	experience = new_value
	
	if not old_level == level:
		recalculate_stats()
	print("xp", experience)
	
	
