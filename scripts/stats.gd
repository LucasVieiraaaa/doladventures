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
signal experience_changed

@export var base_max_health: int = 100
@export var base_defense: float = 10.0
@export var base_attack: float = 10.0

@export var experience: int = 0: set = _on_experience_set

var level: int:
	get(): return floor(max(1.0, sqrt(experience/25.0) + 0.5))
var current_max_health: float = 100.0
var current_defense: float = 10.0
var current_attack: float = 10.0

var health: float = 0.0: set = _on_health_set

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

func _on_health_set(new_value: float) -> void:
	health = clampf(new_value, 0.0, current_max_health)
	health_changed.emit(health, current_max_health)
	if health <= 0.0:
		health_depleated.emit()

func _on_experience_set(new_value: int) -> void:
	var old_level: int = level

	experience = maxi(0, new_value)

	if old_level != level:
		recalculate_stats()

	experience_changed.emit()


# =========================================================
# XP / LEVEL
# =========================================================

func get_xp_for_level(target_level: int) -> int:
	target_level = maxi(target_level, 1)

	if target_level == 1:
		return 0

	return ceili(
		25.0 * pow(target_level - 0.5, 2.0)
	)


func get_xp_in_current_level() -> int:
	return experience - get_xp_for_level(level)


func get_xp_needed_for_current_level() -> int:
	return (
		get_xp_for_level(level + 1)
		- get_xp_for_level(level)
	)


func get_xp_for_next_level() -> int:
	return get_xp_for_level(level + 1)


# =========================================================
# JUTSUS
# =========================================================

func _damage_while_doing_jutsu(jutsu_name: String):
	match jutsu_name:
		"rasengan":
			base_attack = (base_attack * 2)
	
func _get_attack_normal_when_done_jutsu(jutsu_name: String):
	match jutsu_name:
		"rasengan":
			base_attack = (base_attack / 2) 
