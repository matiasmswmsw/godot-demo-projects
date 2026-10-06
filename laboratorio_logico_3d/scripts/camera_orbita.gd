# camera_orbita.gd
# Permite girar a câmera em volta da bancada.
# Botão direito do mouse + arrastar = girar. Roda do mouse = aproximar/afastar.
extends Node3D

@export var sensibilidade: float = 0.005
@export var zoom_minimo: float = 3.0
@export var zoom_maximo: float = 9.0

var girando: bool = false

@onready var camera: Camera3D = $Camera3D


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			girando = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			mudar_zoom(-0.4)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			mudar_zoom(0.4)
	elif event is InputEventMouseMotion and girando:
		rotation.y -= event.relative.x * sensibilidade
		# clamp limita o ângulo para a câmera não passar por baixo da mesa.
		rotation.x = clamp(rotation.x - event.relative.y * sensibilidade, -1.4, -0.15)


func mudar_zoom(quantidade: float) -> void:
	camera.position.z = clamp(camera.position.z + quantidade, zoom_minimo, zoom_maximo)
