class_name InteractionArea extends Area3D

@export var interact_on_enter: bool = false
@export var interact_visualizer: InteractVisualizer:
	set(value):
		interact_visualizer = value
		interact_visualizer.interaction_area = self

@export var is_interact_on_busy: bool = false

@export var can_interact: bool = true
var interactor_in_area: Player

static var busy_area: InteractionArea

signal interacted(interactor)

func _ready() -> void:
	body_entered.connect(on_body_entered)
	body_exited.connect(on_body_exited)


func _physics_process(_delta: float) -> void:
	if busy_area == null and interactor_in_area != null:
		busy_area = self
		# Включаем визуализатор, если зона стала активной в физическом процессе
		if interact_visualizer:
			interact_visualizer.toggle(true)


func on_body_entered(body):
	if not can_interact:
		return
		
	if body is not Player:
		return
		
	interactor_in_area = body
	
	if busy_area == null or is_interact_on_busy:
		if busy_area == null:
			busy_area = self
			
		# ВКЛЮЧАЕМ АУТЛАЙН: игрок подошел, и зона свободна для взаимодействия
		if interact_visualizer:
			interact_visualizer.toggle(true)
		
		if interact_on_enter:
			interacted.emit(interactor_in_area)


func on_body_exited(body):
	if body is not Player:
		return
		
	interactor_in_area = null
	
	# ВЫКЛЮЧАЕМ АУТЛАЙН: игрок отошел от объекта
	if interact_visualizer:
		interact_visualizer.toggle(false)
		
	if busy_area == self:
		busy_area = null


func _input(event: InputEvent) -> void:
	if not can_interact or (busy_area != self and not is_interact_on_busy):
		return
		
	if Input.is_action_just_pressed("interaction") and not interact_on_enter:
		if interactor_in_area != null:
			interacted.emit(interactor_in_area)
