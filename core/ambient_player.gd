extends Node

# Плееры и твины для эмбиента (остаются 2D)
var _ambient_player: AudioStreamPlayer
var _ambient_tween: Tween

# Плеер для музыки меняем на AudioStreamPlayer3D
var _music_player: AudioStreamPlayer3D
var _music_tween: Tween

var amb_db = -12

func _ready() -> void:
	# Инициализация эмбиента
	_ambient_player = AudioStreamPlayer.new()
	add_child(_ambient_player)
	_ambient_player.bus = &"Ambient"
	
	# Инициализация музыки как 3D-плеера
	_music_player = AudioStreamPlayer3D.new()
	add_child(_music_player)
	_music_player.bus = &"Ambient" # Если создашь автобус Music, не забудь поменять


# =============================================================================
# МЕТОДЫ ДЛЯ ЭМБИЕНТА (Без изменений)
# =============================================================================

func play_ambient(stream: AudioStream, fade_time: float = 1.5) -> void:
	if _ambient_player.stream == stream and _ambient_player.playing:
		return
		
	if _ambient_tween and _ambient_tween.is_valid():
		_ambient_tween.kill()
		
	_ambient_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	if _ambient_player.playing:
		_ambient_tween.tween_property(_ambient_player, "volume_db", -80.0, fade_time * 0.5)
		_ambient_tween.tween_callback(func(): 
			_ambient_player.stream = stream
			_ambient_player.play()
		)
		_ambient_tween.tween_property(_ambient_player, "volume_db", amb_db, fade_time * 0.5)
	else:
		_ambient_player.volume_db = -80.0
		_ambient_player.stream = stream
		_ambient_player.play()
		_ambient_tween.tween_property(_ambient_player, "volume_db", amb_db, fade_time)

func stop_ambient(fade_time: float = 1.5) -> void:
	if !_ambient_player.playing:
		return
		
	if _ambient_tween and _ambient_tween.is_valid():
		_ambient_tween.kill()
		
	_ambient_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_ambient_tween.tween_property(_ambient_player, "volume_db", -80.0, fade_time)
	_ambient_tween.tween_callback(_ambient_player.stop)


# =============================================================================
# МЕТОДЫ ДЛЯ МУЗЫКИ (ОБНОВЛЕННЫЕ ПОД 3D)
# =============================================================================

## Плавно запускает музыкальный трек в 3D пространстве
## position - Vector3 глобальная позиция источника звука
## max_distance - дистанция в метрах, дальше которой музыку вообще не слышно
func play_music(stream: AudioStream, position: Vector3, max_distance: float = 20.0, fade_time: float = 1.5) -> void:
	# Обновляем позицию и дальность в любом случае (даже если трек уже играет)
	_music_player.global_position = position
	_music_player.max_distance = max_distance

	if _music_player.stream == stream and _music_player.playing:
		return
		
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
		
	_music_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	if _music_player.playing:
		# Твины в 3D работают с volume_db точно так же
		_music_tween.tween_property(_music_player, "volume_db", -80.0, fade_time * 0.5)
		_music_tween.tween_callback(func(): 
			_music_player.stream = stream
			_music_player.play()
		)
		_music_tween.tween_property(_music_player, "volume_db", 0.0, fade_time * 0.5)
	else:
		_music_player.volume_db = -80.0
		_music_player.stream = stream
		_music_player.play()
		_music_tween.tween_property(_music_player, "volume_db", 0.0, fade_time)

## Плавно останавливает 3D музыку
func stop_music(fade_time: float = 1.5) -> void:
	if !_music_player.playing:
		return
		
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
		
	_music_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_music_tween.tween_property(_music_player, "volume_db", -80.0, fade_time)
	_music_tween.tween_callback(_music_player.stop)


# =============================================================================
# МЕТОДЫ ДЛЯ ПОДВОДНОГО ЗВУКА (LOWPASS ФИЛЬТР)
# =============================================================================

var _filter_tween: Tween

## Плавно включает подводный эффект (заглушает высокие частоты)
## target_hz - до какой частоты срезать (чем ниже, тем глуше звук. 500-1000 — ок)
func mute_to_water(target_hz: float = 800.0, fade_time: float = 1.0) -> void:
	var filter = _get_master_lowpass()
	if not filter:
		push_error("На шине Master не найден эффект AudioEffectLowPassFilter!")
		return
		
	if _filter_tween and _filter_tween.is_valid():
		_filter_tween.kill()
		
	_filter_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# Плавно опускаем частоту среза
	_filter_tween.tween_property(filter, "cutoff_hz", target_hz, fade_time)


## Плавно выключает подводный эффект, возвращая звук в норму
func unmute_from_water(fade_time: float = 1.0) -> void:
	var filter = _get_master_lowpass()
	if not filter:
		return
		
	if _filter_tween and _filter_tween.is_valid():
		_filter_tween.kill()
		
	_filter_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# По умолчанию у LowPass максимальная частота около 20000 Гц (полный спектр)
	_filter_tween.tween_property(filter, "cutoff_hz", 20000.0, fade_time)


# Вспомогательный метод для поиска фильтра на шине Master
func _get_master_lowpass() -> AudioEffectLowPassFilter:
	var bus_index = AudioServer.get_bus_index("Master")
	
	# Ищем фильтр среди всех эффектов на шине
	for i in AudioServer.get_bus_effect_count(bus_index):
		var effect = AudioServer.get_bus_effect(bus_index, i)
		if effect is AudioEffectLowPassFilter:
			return effect
			
	return null
