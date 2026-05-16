extends StateMachine

class_name StateMachineState

var state_machine: StateMachine
var parent_states: Dictionary
var enter_time: int = 0

func enter(props: Dictionary):
	state_machine = props.get("state_machine")
	parent_states = state_machine.states
	enter_time = get_time()

func _physics_process(delta: float) -> void:
	if current_state and is_current():
		current_state.physics_update(delta)

func _process(delta: float) -> void:
	if current_state and is_current():
		current_state.update(delta)

func _input(event: InputEvent) -> void:
	if current_state and is_current():
		current_state.input(event)

func _unhandled_input(event: InputEvent) -> void:
	if current_state and is_current():
		current_state.unhandled_input(event)

func physics_update(delta):
	pass

func update(delta):
	pass

func exit():
	pass

func input(event: InputEvent):
	pass

func unhandled_input(event: InputEvent):
	pass

func get_left_time():
	return (Time.get_ticks_msec()-enter_time)/1000.0

func get_time():
	return Time.get_ticks_msec()

func change_parent_state(state: State, props: Dictionary = {}):
	state_machine.change_state(state, props)

func is_current():
	return state_machine.current_state == self
