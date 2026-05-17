extends ColorRect

@export var target_speed: float = 2.0
var current_speed: float = 2.0
var custom_time: float = 0.0

func _process(delta: float) -> void:
	# 1. Плавно приближаем текущую скорость к целевой
	# 5.0 — это скорость изменения самой скорости, можно крутить
	current_speed = lerp(current_speed, target_speed, delta * 5.0)
	
	# 2. Наращиваем кастомное время с учетом актуальной плавной скорости
	custom_time += delta * current_speed
	
	# Чтобы число не улетало в бесконечность, сбрасываем его при достижении 1.0
	# (так как в шейдере все равно используется mod(..., 1.0))
	if custom_time >= 1.0:
		custom_time = fmod(custom_time, 1.0)
		
	# 3. Отдаем значение в шейдер
	material.set_shader_parameter("custom_time", custom_time)
