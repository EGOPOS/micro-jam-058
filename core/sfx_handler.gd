class_name SfxHandler extends Node

#@export var decrease_music_volume: bool = false

var sfxs: Dictionary = {
	
}

func _ready():
	for child in get_children():
		if child is AudioStreamPlayer3D or child is AudioStreamPlayer:
			sfxs[child.name] = child
			child.bus = "Sfx"


func get_player(sfx: String):
	return sfxs[sfx]


func play(sfx: String):
	sfxs[sfx].play()
	
	#if decrease_music_volume and sfxs[sfx].stream:
		#MusicManager.set_music_volume(MusicManager.default_volume - 15)
		#await get_tree().create_timer((sfxs[sfx] as AudioStreamPlayer).stream.get_length(), false).timeout
		#MusicManager.set_music_volume(MusicManager.default_volume)

func stop(sfx: String):
	sfxs[sfx].stop()

func is_playing(sfx: String):
	return sfxs[sfx].is_playing()
