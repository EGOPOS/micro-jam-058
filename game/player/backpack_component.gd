class_name BackpackComponent extends Node

@export var payload: int = 3

var storage: Array = []

signal overweight_changed()

func _ready():
	pass


func is_can_put():
	return true


func put_to_storage(resource: SellableResource):
	storage.append(resource)
	resource.hide()
	
	overweight_changed.emit()


func put_on_floor_from_storage() -> SellableResource:
	var hit = Help.get_camera_center_hit()
	if hit.is_empty() or storage.is_empty():
		return
	
	
	var resource = _get_next_resource()
	if resource == null: return null
	
	resource.global_position = hit.position
	resource.show()
	storage.erase(resource)
	
	overweight_changed.emit()
	
	return resource


func take_from_storage() -> SellableResource:
	if storage.is_empty():
		return null
	
	var resource = _get_next_resource()
	if resource == null: return null
	
	storage.erase(resource)
	
	overweight_changed.emit()
	
	return resource


func _get_next_resource():
	var resource = storage.back()
	if (resource as Node).is_in_group("endgame"):
		if storage.size() == 1:
			return null
		else:
			return storage.front()
	return resource

func get_overweight():
	return max(storage.size() - payload, 0)
