# bancada.gd
# Cena 3D reutilizável: a bancada com as chaves A e B, o CI e o LED.
# É usada pelo Modo Livre e pelo Modo Desafio (as duas cenas "instanciam" esta).
# A bancada NÃO decide qual é a porta lógica: ela só avisa quando as entradas
# mudam (sinal) e mostra a saída que receber.
extends Node3D

# Emitido sempre que a chave A ou a chave B muda.
signal entradas_mudaram(a: bool, b: bool)

const COR_FIO_DESLIGADO := Color(0.3, 0.3, 0.3)
const COR_FIO_LIGADO := Color(1.0, 0.75, 0.1)

# Valores atuais das entradas.
var a: bool = false
var b: bool = false

@onready var chave_a = $ChaveA
@onready var chave_b = $ChaveB
@onready var chip = $Chip
@onready var led = $LED
@onready var fio_a: MeshInstance3D = $FioA
@onready var fio_b: MeshInstance3D = $FioB
@onready var fio_s: MeshInstance3D = $FioS


func _ready() -> void:
	chave_a.alternada.connect(_on_chave_a_alternada)
	chave_b.alternada.connect(_on_chave_b_alternada)
	atualizar_fios_entrada()


func _on_chave_a_alternada(ligada: bool) -> void:
	a = ligada
	atualizar_fios_entrada()
	entradas_mudaram.emit(a, b)


func _on_chave_b_alternada(ligada: bool) -> void:
	b = ligada
	atualizar_fios_entrada()
	entradas_mudaram.emit(a, b)


# Atalhos de teclado: tecla A alterna a chave A e tecla B alterna a chave B.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_A:
			chave_a.alternar()
		elif event.keycode == KEY_B:
			chave_b.alternar()


# Mostra o valor da saída S no LED e no fio de saída.
func mostrar_saida(s: bool) -> void:
	led.acender(s)
	pintar_fio(fio_s, s)


# Escreve o texto em cima do CI (ex.: "7408\nAND" ou "????\n?").
func mostrar_porta(nome: String, ci: String) -> void:
	chip.definir_texto(ci + "\n" + nome)


# Habilita ou desabilita a entrada B (a porta NOT só tem uma entrada).
func usar_entrada_b(usar: bool) -> void:
	chave_b.definir_ativa(usar)
	fio_b.visible = usar
	if not usar:
		b = false


# Desliga as duas chaves (início de uma nova rodada).
func reiniciar_chaves() -> void:
	a = false
	b = false
	chave_a.definir_estado(false)
	chave_b.definir_estado(false)
	atualizar_fios_entrada()


func atualizar_fios_entrada() -> void:
	pintar_fio(fio_a, a)
	pintar_fio(fio_b, b)


# Fio com nível 1 fica amarelo; com nível 0, cinza.
func pintar_fio(fio: MeshInstance3D, ligado: bool) -> void:
	var material: StandardMaterial3D = fio.material_override
	if ligado:
		material.albedo_color = COR_FIO_LIGADO
	else:
		material.albedo_color = COR_FIO_DESLIGADO
