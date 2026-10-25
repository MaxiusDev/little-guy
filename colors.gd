extends Node

@export var active : bool = true

var blueColors = [
	preload("res://Materials/Blue/lightBlue.tres"),
	preload("res://Materials/Blue/water.tres"),
]
var orangeColors = [
	preload("res://Materials/Orange/brown.tres"),
]
var greenColors = [
	preload("res://Materials/Green/lightGreen.tres"),
]

var outlineColors = [
	preload("res://Materials/Blue/lightBlue_Outline.tres"),
	preload("res://Materials/Blue/water_Outline.tres"),
	preload("res://Materials/Green/lightGreen_Outline.tres"),
	preload("res://Materials/Orange/brown_Outline.tres"),
]

var originalColors = {}

func _ready() -> void:
	if not active: return
	var colorGroups = [blueColors, greenColors, orangeColors]
	
	for colorGroup in colorGroups:
		for material in colorGroup:
			if material is StandardMaterial3D:
				originalColors[material] = material.albedo_color
				material.albedo_color = Color.WHITE
				
	for material in outlineColors:
		originalColors[material] = material.albedo_color
		material.albedo_color = Color("514D4A")
		
	await get_tree().create_timer(10.0).timeout
	unlockBlue()
	
func tweenOriginalColor(material):
	create_tween().tween_property(material, "albedo_color", originalColors[material], 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
func unlockGreen():
	tweenOriginalColor(outlineColors[2])
			
	for material in greenColors:
		if material is StandardMaterial3D and originalColors[material]:
			print(material)
			var colorTween = create_tween()
			colorTween.tween_property(material, "albedo_color", originalColors[material], 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			
func unlockBlue():
	tweenOriginalColor(outlineColors[0])
	tweenOriginalColor(outlineColors[1])
	
	for material in blueColors:
		if material is StandardMaterial3D and originalColors[material]:
			print(material)
			var colorTween = create_tween()
			colorTween.tween_property(material, "albedo_color", originalColors[material], 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
