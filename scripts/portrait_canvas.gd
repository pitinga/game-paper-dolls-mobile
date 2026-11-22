extends Node2D

const Art = preload("res://scripts/doll_art.gd")
const Sprites = preload("res://scripts/paper_sprites.gd")

var studio_state: Object


func _draw() -> void:
	if studio_state != null:
		Art.draw_background(self, int(studio_state.background_index))
		Sprites.draw_stage(self, studio_state)

