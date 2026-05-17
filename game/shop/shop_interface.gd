extends Control

@export var slot_scene: PackedScene 

@onready var cash_count_label: Label = %CashCountLabel
@onready var items_slots_container: VBoxContainer = %ItemsSlotsContainer

signal purchased(id)

func _ready() -> void:
	_update_cash_display()
	_build_shop_menu()
	
	var viewport = get_viewport()
	if viewport is SubViewport:
		viewport.handle_input_locally = true
	Global.cash_changed.connect(_update_cash_display)
	Global.shop_interface = self
	
	purchased.connect(_build_shop_menu.unbind(1))

# Обновление текста с балансом
func _update_cash_display() -> void:
	if cash_count_label:
		cash_count_label.text = str(Global.cash) + " $"

# Генерация слотов в контейнере
func _build_shop_menu() -> void:
	if not slot_scene:
		push_error("Забыли прикрепить 'slot_scene' в инспекторе для скрипта магазина!")
		return
		
	# Очищаем контейнер от старых тестовых нод, если они там были
	for child in items_slots_container.get_children():
		child.queue_free()
		
	# Циклом создаем слоты под каждый товар
	for id in Global.shop_products:
		var slot_instance = slot_scene.instantiate()
		
		# Используем наши сеттеры из прошлого шага!
		var product = Global.shop_products[id]
		slot_instance.item_name = product.name
		slot_instance.price = product.price
		slot_instance.item_id = id
		slot_instance.buy_callback = func():
			if _try_purchase(id):
				product.callback.call()
				purchased.emit(id)
			
		# Добавляем готовый слот в твой VBoxContainer
		items_slots_container.add_child(slot_instance)

func get_slot_by_item_id(target_id: String) -> PanelContainer:
	# Перебираем все дочерние узлы внутри нашего VBoxContainer
	for slot in items_slots_container.get_children():
		# Проверяем, есть ли у ноды наше свойство item_id и совпадает ли оно
		if "item_id" in slot and slot.item_id == target_id:
			return slot # Слот найден, возвращаем его и выходим из функции
			
	return null # Если цикл кончился, а хомяка так и не нашли

func _try_purchase(id) -> bool:
	var product = Global.shop_products[id]
	var cost = product["price"]
	var item_name = product["name"]
	
	if Global.cash >= cost:
		Global.cash -= cost # Сеттер сам обновит интерфейс
		return true
	else:
		print("Нищеброд! Не хватает денег на: ", item_name, " (Нужно: ", cost, ")")
		return false
