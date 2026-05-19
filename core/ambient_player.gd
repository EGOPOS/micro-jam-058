extends Node

# =============================================================================
# ЭМБИЕНТ И ФИЛЬТРЫ (Без изменений)
# =============================================================================
var _ambient_player: AudioStreamPlayer
var _ambient_tween: Tween
var amb_db = -12
var _filter_tween: Tween

func _ready() -> void:
	# Инициализация эмбиента
	_ambient_player = AudioStreamPlayer.new()
	add_child(_ambient_player)
	_ambient_player.bus = &"Ambient"


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

func mute_to_water(target_hz: float = 800.0, fade_time: float = 1.0) -> void:
	var filter = _get_master_lowpass()
	if not filter:
		push_error("На шине Master не найден эффект AudioEffectLowPassFilter!")
		return
	if _filter_tween and _filter_tween.is_valid():
		_filter_tween.kill()
	_filter_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_filter_tween.tween_property(filter, "cutoff_hz", target_hz, fade_time)

func unmute_from_water(fade_time: float = 1.0) -> void:
	var filter = _get_master_lowpass()
	if not filter:
		return
	if _filter_tween and _filter_tween.is_valid():
		_filter_tween.kill()
	_filter_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_filter_tween.tween_property(filter, "cutoff_hz", 20000.0, fade_time)

func _get_master_lowpass() -> AudioEffectLowPassFilter:
	var bus_index = AudioServer.get_bus_index("Master")
	for i in AudioServer.get_bus_effect_count(bus_index):
		var effect = AudioServer.get_bus_effect(bus_index, i)
		if effect is AudioEffectLowPassFilter:
			return effect
	return null

# =============================================================================
# ДИНАМИЧЕСКАЯ МУЗЫКА (Stem mixing, 2D и 3D)
# =============================================================================

# Храним активные треки в словаре: { "id_трека": { "player": Node, "tween": Tween } }
var _active_music: Dictionary = {}

## Запускает музыкальный слой.
## id - уникальное имя трека (например "drums", "melody", "radio").
## is_3d - если true, будет играть из точки, если false - обычная 2D фоновая музыка.
## start_muted - если true, трек запустится параллельно с другими, но на громкости -80db (чтобы потом его вывести).
func play_music(id: String, stream: AudioStream, is_3d: bool = false, start_muted: bool = false, position: Vector3 = Vector3.ZERO, max_distance: float = 20.0, fade_time: float = 1.5) -> void:
	var target_db = -80.0 if start_muted else 0.0
	
	# Если трек с таким ID есть, но мы хотим сменить его тип (2D на 3D или наоборот), удаляем старый
	if _active_music.has(id):
		var old_player = _active_music[id].player
		if (is_3d and not old_player is AudioStreamPlayer3D) or (not is_3d and not old_player is AudioStreamPlayer):
			old_player.queue_free()
			_active_music.erase(id)
			
	# Если плеера под этот ID еще нет — создаем его динамически
	if not _active_music.has(id):
		var new_player = AudioStreamPlayer3D.new() if is_3d else AudioStreamPlayer.new()
		add_child(new_player)
		new_player.bus = &"Ambient" # Замени на Music, если надо
		_active_music[id] = { "player": new_player, "tween": null }
		
	var player = _active_music[id].player
	
	# Обновляем 3D параметры, если это 3D
	if is_3d:
		player.global_position = position
		player.max_distance = max_distance
		
	# Если этот трек УЖЕ играет, просто плавно выравниваем его громкость до нужной
	if player.stream == stream and player.playing:
		fade_music(id, target_db, fade_time)
		return

	# Если это новый трек, запускаем его
	_kill_music_tween(id)
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_active_music[id].tween = tween
	
	if player.playing:
		# Плавный переход (crossfade) старого трека на новый
		tween.tween_property(player, "volume_db", -80.0, fade_time * 0.5)
		tween.tween_callback(func(): 
			player.stream = stream
			player.play()
		)
		tween.tween_property(player, "volume_db", target_db, fade_time * 0.5)
	else:
		# Запуск с нуля
		player.volume_db = -80.0
		player.stream = stream
		player.play()
		tween.tween_property(player, "volume_db", target_db, fade_time)

## Плавно меняет громкость конкретного трека (идеально для stem-mixing).
## Например, fade_music("drums", 0.0) — выведет ударные из тишины.
func fade_music(id: String, target_db: float, fade_time: float = 1.5) -> void:
	if not _active_music.has(id):
		return
		
	_kill_music_tween(id)
	var player = _active_music[id].player
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_active_music[id].tween = tween
	
	tween.tween_property(player, "volume_db", target_db, fade_time)

## Останавливает конкретный трек по его ID.
func stop_music(id: String, fade_time: float = 1.5) -> void:
	if not _active_music.has(id):
		return
		
	var player = _active_music[id].player
	if not player.playing:
		return
		
	_kill_music_tween(id)
	var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_active_music[id].tween = tween
	
	tween.tween_property(player, "volume_db", -80.0, fade_time)
	tween.tween_callback(player.stop)

## Останавливает ВООБЩЕ ВСЮ музыку (удобно при завершении уровня).
func stop_all_music(fade_time: float = 1.5) -> void:
	for id in _active_music.keys():
		stop_music(id, fade_time)

# Вспомогательная функция, чтобы очищать твины и не плодить ошибки
func _kill_music_tween(id: String) -> void:
	if _active_music[id].tween and _active_music[id].tween.is_valid():
		_active_music[id].tween.kill()
