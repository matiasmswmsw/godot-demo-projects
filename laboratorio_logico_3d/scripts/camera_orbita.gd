# camera_orbita.gd
# Câmera que gira em volta da protoboard, aproxima e se move para os lados.
# Mouse:   botão direito + arrastar = girar (para os lados E para cima/baixo)
#          botão do meio (ou Shift + botão direito) + arrastar = mover
#          roda = aproximar/afastar
# Teclado: setas = girar • Shift + setas = mover • + e − = zoom
#          1 = vista inclinada • 2 = vista de cima • 3 = vista de frente
extends Node3D

@export var sensibilidade: float = 0.006
@export var zoom_minimo: float = 1.2
@export var zoom_maximo: float = 8.0
@export var suavidade: float = 10.0 # maior = câmera chega mais rápido no lugar
@export var limite_movimento: Vector2 = Vector2(2.5, 1.8) # até onde dá para mover (x, z)

# Valores "alvo": o mouse e o teclado mudam estes, e a câmera vai até eles aos poucos.
var giro_alvo: float = 0.0 # ângulo para os lados (eixo Y)
var inclinacao_alvo: float = -1.0 # ângulo para cima/baixo (eixo X)
var distancia_alvo: float = 3.8
var centro_alvo: Vector3 = Vector3.ZERO

var girando: bool = false
var movendo: bool = false
var vista_inicial: Dictionary = {}

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	# A posição inicial vem do que foi colocado na cena (Inspetor).
	giro_alvo = rotation.y
	inclinacao_alvo = rotation.x
	distancia_alvo = camera.position.z
	centro_alvo = position
	vista_inicial = {"giro": giro_alvo, "inclinacao": inclinacao_alvo, "distancia": distancia_alvo, "centro": centro_alvo}


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			girando = event.pressed and not event.shift_pressed
			movendo = event.pressed and event.shift_pressed
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			movendo = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			distancia_alvo = clampf(distancia_alvo * 0.9, zoom_minimo, zoom_maximo)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			distancia_alvo = clampf(distancia_alvo * 1.1, zoom_minimo, zoom_maximo)
	elif event is InputEventMouseMotion:
		if girando:
			girar(-event.relative.x * sensibilidade, -event.relative.y * sensibilidade)
		elif movendo:
			mover(-event.relative.x * 0.0015 * distancia_alvo, -event.relative.y * 0.0015 * distancia_alvo)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				definir_vista("inclinada")
			KEY_2:
				definir_vista("cima")
			KEY_3:
				definir_vista("frente")


func _process(delta: float) -> void:
	# Teclado: segurar a tecla move continuamente.
	var horizontal: float = Input.get_axis("ui_left", "ui_right")
	var vertical: float = Input.get_axis("ui_up", "ui_down")
	if Input.is_key_pressed(KEY_SHIFT):
		mover(horizontal * 1.5 * delta, vertical * 1.5 * delta)
	else:
		girar(-horizontal * 1.5 * delta, -vertical * 1.0 * delta)
	if Input.is_key_pressed(KEY_EQUAL) or Input.is_key_pressed(KEY_KP_ADD):
		distancia_alvo = clampf(distancia_alvo - 2.0 * delta, zoom_minimo, zoom_maximo)
	if Input.is_key_pressed(KEY_MINUS) or Input.is_key_pressed(KEY_KP_SUBTRACT):
		distancia_alvo = clampf(distancia_alvo + 2.0 * delta, zoom_minimo, zoom_maximo)

	# Suaviza: a cada quadro anda uma parte do caminho até o alvo.
	var t: float = clampf(suavidade * delta, 0.0, 1.0)
	rotation.y = lerp_angle(rotation.y, giro_alvo, t)
	rotation.x = lerpf(rotation.x, inclinacao_alvo, t)
	position = position.lerp(centro_alvo, t)
	camera.position.z = lerpf(camera.position.z, distancia_alvo, t)


func girar(lados: float, cima_baixo: float) -> void:
	giro_alvo += lados
	# clamp: não deixa a câmera passar por baixo da mesa nem virar de cabeça para baixo.
	inclinacao_alvo = clampf(inclinacao_alvo + cima_baixo, -1.55, -0.05)


# Move o centro da câmera no plano da mesa, de acordo com o lado para onde ela olha.
func mover(lados: float, frente: float) -> void:
	var direita := Vector3(cos(giro_alvo), 0, -sin(giro_alvo))
	var para_tras := Vector3(sin(giro_alvo), 0, cos(giro_alvo))
	centro_alvo += direita * lados + para_tras * frente
	centro_alvo.x = clampf(centro_alvo.x, -limite_movimento.x, limite_movimento.x)
	centro_alvo.z = clampf(centro_alvo.z, -limite_movimento.y, limite_movimento.y)


func definir_vista(nome: String) -> void:
	match nome:
		"cima":
			giro_alvo = 0.0
			inclinacao_alvo = -1.55
			distancia_alvo = 3.6
			centro_alvo = Vector3.ZERO
		"frente":
			giro_alvo = 0.0
			inclinacao_alvo = -0.35
			distancia_alvo = 3.4
			centro_alvo = Vector3(0, 0, 0.2)
		_:
			giro_alvo = vista_inicial["giro"]
			inclinacao_alvo = vista_inicial["inclinacao"]
			distancia_alvo = vista_inicial["distancia"]
			centro_alvo = vista_inicial["centro"]
