extends Control

@export var slot_scene: PackedScene 

@onready var cash_count_label: Label = %CashCountLabel
@onready var items_slots_container: VBoxContainer = %ItemsSlotsContainer

# Текущие деньги игрока (если у тебя есть синглтон игрока, можно связать с ним)
var player_cash: int = 400:
	set(value):
		player_cash = value
		_update_cash_display()

# Наша «база данных» товаров для этого магазина
var shop_products: Array[Dictionary] = [
	{"id": "iron_pickaxe", "name": "Железная кирка", "price": 100},
	{"id": "diamond_pickaxe", "name": "Алмазная кирка", "price": 300},
	{"id": "speed_potion", "name": "Зелье скорости", "price": 45},
	{"id": "lucky_charm", "name": "Амулет удачи", "price": 150}
]

func _ready() -> void:
	_update_cash_display()
	_build_shop_menu()
	
	var viewport = get_viewport()
	if viewport is SubViewport:
		viewport.handle_input_locally = true
	gui_input.connect(func(event): print("Магазин поймал ивент: ", event))

# Обновление текста с балансом
func _update_cash_display() -> void:
	if cash_count_label:
		cash_count_label.text = str(player_cash) + " $"

# Генерация слотов в контейнере
func _build_shop_menu() -> void:
	if not slot_scene:
		push_error("Забыли прикрепить 'slot_scene' в инспекторе для скрипта магазина!")
		return
		
	# Очищаем контейнер от старых тестовых нод, если они там были
	for child in items_slots_container.get_children():
		child.queue_free()
		
	# Циклом создаем слоты под каждый товар
	for product in shop_products:
		var slot_instance = slot_scene.instantiate()
		
		# Используем наши сеттеры из прошлого шага!
		slot_instance.item_name = product.name
		slot_instance.price = product.price
		slot_instance.item_id = product.id
		
		# Передаем уникальную лямбда-функцию для покупки конкретно этого айтема
		slot_instance.buy_callback = func():
			_try_purchase(product)
			
		# Добавляем готовый слот в твой VBoxContainer
		items_slots_container.add_child(slot_instance)

func get_slot_by_item_id(target_id: String) -> PanelContainer:
	# Перебираем все дочерние узлы внутри нашего VBoxContainer
	for slot in items_slots_container.get_children():
		# Проверяем, есть ли у ноды наше свойство item_id и совпадает ли оно
		if "item_id" in slot and slot.item_id == target_id:
			return slot # Слот найден, возвращаем его и выходим из функции
			
	return null # Если цикл кончился, а хомяка так и не нашли

# Общая функция обработки покупки
func _try_purchase(product_data: Dictionary) -> void:
	var cost = product_data["price"]
	var item_name = product_data["name"]
	var item_id = product_data["id"]
	
	if player_cash >= cost:
		player_cash -= cost # Сеттер сам обновит интерфейс
		_give_item_to_player(item_id)
		print("Куплено: ", item_name, ". Остаток: ", player_cash)
	else:
		print("Нищеброд! Не хватает денег на: ", item_name, " (Нужно: ", cost, ")")

func _give_item_to_player(item_id: String) -> void:
	# Сюда впиши логику интеграции с твоим инвентарем игрока
	# Например: PlayerStats.inventory.append(item_id)
	match item_id:
		"iron_pickaxe":
			print("Выдали железную кирку")
		"diamond_pickaxe":
			print("Выдали алмазную кирку")
		_:
			print("Выдали что-то другое: ", item_id)


func _shortcut_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		print("Магазин ЖЕСТКО перехватил мышь через shortcut: ", event)
