extends Node2D

const Art = preload("res://scripts/doll_art.gd")

var studio_state: Object


func _draw() -> void:
	if studio_state != null:
		Art.draw_stage(self, studio_state)

