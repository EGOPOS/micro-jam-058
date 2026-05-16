extends Node

var actions = {
	"movement_jump": 0.05,
	"mouse_left": 0.05,
	"mouse_right": 0.05,
}

var _input_buffer: Array[String]

# Using process cause _input ignore action hold pressing
func _process(delta: float) -> void:
	for action in actions.keys():
		if Input.is_action_pressed(action):
			_input_buffer.append(action)
			get_tree().create_timer(actions[action]).timeout.connect( Callable(func(action: String):
				_input_buffer.remove_at(_input_buffer.rfind(action))
			).bind(action) )

func is_action_in_buffer(action: String):
	if _input_buffer.find(action) != -1:
		return true
	return false
