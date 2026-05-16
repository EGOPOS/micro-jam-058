class_name StateMachine extends Node

var current_state: State
var states: Dictionary = {}
var additional_props: Dictionary = {}

func _ready():
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.state_machine = self

func set_additional_props(new_props: Dictionary = {}):
	additional_props = new_props

func change_state(new_state: State, props: Dictionary = {}):
	if current_state:
		current_state.exit()
	
	current_state = new_state
	
	if current_state:
		var all_props = props.duplicate().merged(additional_props)
		all_props["state_machine"] = self
		current_state.enter(all_props)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _input(event: InputEvent) -> void:
	if current_state:
		current_state.input(event)

func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.unhandled_input(event)
