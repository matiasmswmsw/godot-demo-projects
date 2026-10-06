# chave.gd
# Uma chave (interruptor) 3D que pode ser ligada e desligada com um clique.
# Representa uma ENTRADA do circuito: ligada = nível lógico 1, desligada = 0.
extends Area3D

# Sinal próprio: avisa a cena "pai" sempre que a chave muda de estado.
signal alternada(ligada: bool)

# @export faz a variável aparecer no Inspetor do Godot.
@export var nome: String = "A"

var ligada: bool = false # estado atual da chave
var ativa: bool = true # se false, a chave não pode ser usada (ex.: porta NOT)

# @onready busca os nós filhos quando a cena fica pronta.
@onready var alavanca: Node3D = $Alavanca
@onready var haste: MeshInstance3D = $Alavanca/Haste
@onready var rotulo: Label3D = $Rotulo
@onready var estado: Label3D = $Estado

const COR_LIGADA := Color(0.2, 0.85, 0.3) # verde
const COR_DESLIGADA := Color(0.85, 0.15, 0.15) # vermelho
const COR_INATIVA := Color(0.4, 0.4, 0.4) # cinza


func _ready() -> void:
	rotulo.text = nome
	# Conecta os sinais da Area3D às funções deste script.
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	atualizar_visual()


# Chamada quando o mouse faz algo em cima da área de clique da chave.
func _on_input_event(_camera: Node, event: InputEvent, _posicao: Vector3, _normal: Vector3, _forma: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		alternar()


# Destaca a chave quando o mouse passa por cima.
func _on_mouse_entered() -> void:
	if ativa:
		scale = Vector3(1.1, 1.1, 1.1)


func _on_mouse_exited() -> void:
	scale = Vector3.ONE


# Inverte o estado da chave (liga se estava desligada e vice-versa).
func alternar() -> void:
	if not ativa:
		return
	ligada = not ligada
	atualizar_visual()
	alternada.emit(ligada)


# Muda o estado sem emitir o sinal (usado para reiniciar a bancada).
func definir_estado(valor: bool) -> void:
	ligada = valor
	atualizar_visual()


func definir_ativa(valor: bool) -> void:
	ativa = valor
	if not ativa:
		ligada = false
	atualizar_visual()


# Atualiza a aparência: inclina a alavanca, muda a cor e o texto 0/1.
func atualizar_visual() -> void:
	var material: StandardMaterial3D = haste.material_override
	var angulo: float
	if ligada:
		angulo = deg_to_rad(-30)
		material.albedo_color = COR_LIGADA
		estado.text = "1"
	else:
		angulo = deg_to_rad(30)
		material.albedo_color = COR_DESLIGADA
		estado.text = "0"

	if not ativa:
		material.albedo_color = COR_INATIVA
		estado.text = "-"

	# Tween: anima a rotação da alavanca suavemente em 0,15 segundos.
	var tween := create_tween()
	tween.tween_property(alavanca, "rotation:z", angulo, 0.15)
