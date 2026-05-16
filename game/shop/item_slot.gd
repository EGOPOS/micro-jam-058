@tool
extends PanelContainer

@onready var slot_item_name: Label = %SlotItemName
@onready var slot_item_price: Label = %SlotItemPrice
@onready var buy_button: Button = %BuyButton

var item_id: String = ""

var buy_callback: Callable

@export var item_name: String = "Item":
	set(value):
		item_name = value
		if is_node_ready():
			slot_item_name.text = value

@export var price: int = 0:
	set(value):
		price = value
		if is_node_ready():
			slot_item_price.text = str(value)

func _ready() -> void:
	slot_item_name.text = item_name
	slot_item_price.text = str(price)
	
	buy_button.pressed.connect(_on_buy_button_pressed)

func _on_buy_button_pressed() -> void:
	if buy_callback.is_valid():
		buy_callback.call()
	else:
		print("Для этого слота не задано уникальное действие!")
