# menu.gd
# Tela inicial: mostra um CI e um LED girando em 3D e os botões de navegação.
extends Node3D

const VELOCIDADE_GIRO: float = 0.5 # radianos por segundo
const INTERVALO_PISCA: float = 0.6 # segundos entre cada piscada do LED

var tempo_pisca: float = 0.0

@onready var vitrine: Node3D = $Vitrine
@onready var led = $Vitrine/LED
@onready var chip = $Vitrine/Chip
@onready var label_recorde: Label = $Interface/Tela/Coluna/LabelRecorde


func _ready() -> void:
	# Conectando o sinal "pressed" de cada botão a uma função.
	$Interface/Tela/Coluna/BotaoAprender.pressed.connect(trocar_cena.bind("res://cenas/aprender.tscn"))
	$Interface/Tela/Coluna/BotaoLivre.pressed.connect(_on_botao_livre_pressed)
	$Interface/Tela/Coluna/BotaoDesafio.pressed.connect(trocar_cena.bind("res://cenas/desafio.tscn"))
	$Interface/Tela/Coluna/BotaoErro.pressed.connect(trocar_cena.bind("res://cenas/encontre_erro.tscn"))
	$Interface/Tela/Coluna/BotaoMontar.pressed.connect(trocar_cena.bind("res://cenas/monte_circuito.tscn"))
	$Interface/Tela/Coluna/BotaoSair.pressed.connect(_on_botao_sair_pressed)
	chip.definir_texto("74HC08\nAND")
	label_recorde.text = "Recordes: Descubra a porta %d • Encontre o erro %d • Nível liberado: %d" % [
		Global.recordes["descubra"], Global.recordes["erro"], Global.nivel_liberado]


func _process(delta: float) -> void:
	# Gira a vitrine em volta do eixo Y.
	vitrine.rotation.y += VELOCIDADE_GIRO * delta
	# Faz o LED piscar usando um contador de tempo.
	tempo_pisca += delta
	if tempo_pisca >= INTERVALO_PISCA:
		tempo_pisca = 0.0
		led.acender(not led.aceso)


func trocar_cena(caminho: String) -> void:
	get_tree().change_scene_to_file(caminho)


func _on_botao_livre_pressed() -> void:
	Global.porta_inicial = "AND"
	get_tree().change_scene_to_file("res://cenas/modo_livre.tscn")


func _on_botao_sair_pressed() -> void:
	get_tree().quit()
