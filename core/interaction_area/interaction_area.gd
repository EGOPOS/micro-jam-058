class_name InteractionArea extends Area3D

@export var interact_on_enter: bool = false
@export var interact_visualizer: InteractVisualizer 
@export var is_interact_on_busy: bool = false

@export var can_interact: bool = true
var interactor_in_area: Player

static var busy_area: InteractionArea

signal interacted(interactor)

func _ready() -> void:
	body_entered.connect(on_body_entered)
	body_exited.connect(on_body_exited)


func _physics_process(delta: float) -> void:
	if busy_area == null and interactor_in_area != null:
		busy_area = self


func on_body_entered(body):
	if not can_interact:
		return
	
	if body is not Player:
		return
	
	interactor_in_area = body
	if busy_area == null or is_interact_on_busy:
		if busy_area == null:
			busy_area = self
	
		if interact_on_enter:
			interacted.emit(interactor_in_area)


func on_body_exited(body):
	if body is not Player:
		return
	
	interactor_in_area = null
	if busy_area == self:
		busy_area = null


func _input(event: InputEvent) -> void:
	if not can_interact or (busy_area != self and not is_interact_on_busy):
		return
	
	if Input.is_action_just_pressed("interaction") and not interact_on_enter:
		if interactor_in_area != null:
			interacted.emit(interactor_in_area)
