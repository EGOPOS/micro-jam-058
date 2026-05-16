class_name State extends Node

var state_machine: StateMachine
var states: Dictionary
var enter_time: int = 0

func enter(props: Dictionary):
	state_machine = props.get("state_machine")
	states = state_machine.states
	enter_time = get_time()

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

func change_state(state: State, props: Dictionary = {}):
	state_machine.change_state(state, props)

func get_left_time(since: int = enter_time):
	return (Time.get_ticks_msec()-since)/1000.0

func get_time():
	return Time.get_ticks_msec()
