class_name PlayerState extends State

var player: Player

func enter(props: Dictionary):
	super(props)
	player = props.player
