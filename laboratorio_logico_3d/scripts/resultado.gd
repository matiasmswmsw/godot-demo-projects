# resultado.gd
# Tela final do Modo Desafio: mostra acertos, pontos, tempo e uma mensagem.
extends Control

@onready var label_acertos: Label = $Painel/Coluna/LabelAcertos
@onready var label_pontos: Label = $Painel/Coluna/LabelPontos
@onready var label_tempo: Label = $Painel/Coluna/LabelTempo
@onready var label_mensagem: Label = $Painel/Coluna/LabelMensagem
@onready var label_recorde: Label = $Painel/Coluna/LabelRecorde


func _ready() -> void:
	$Painel/Coluna/Botoes/BotaoNovamente.pressed.connect(_on_botao_novamente_pressed)
	$Painel/Coluna/Botoes/BotaoMenu.pressed.connect(_on_botao_menu_pressed)

	label_acertos.text = "Acertos: %d de %d" % [Global.acertos, Global.total_rodadas]
	label_pontos.text = "Pontos: %d" % Global.pontos
	label_tempo.text = "Tempo total: %.1f s" % Global.tempo_total
	label_mensagem.text = escolher_mensagem(Global.acertos)

	if Global.verificar_recorde():
		label_recorde.text = "Novo recorde!"
	else:
		label_recorde.text = "Recorde atual: %d pontos" % Global.recorde


# Escolhe uma mensagem de acordo com o número de acertos.
func escolher_mensagem(acertos: int) -> String:
	if acertos == Global.total_rodadas:
		return "Excelente! Você domina as portas lógicas!"
	elif acertos >= 3:
		return "Muito bem! Revise as tabelas-verdade das portas que errou."
	elif acertos >= 1:
		return "Bom começo! Treine mais no Modo Livre."
	else:
		return "Não desanime! Use o Modo Livre e a tela de teoria para estudar."


func _on_botao_novamente_pressed() -> void:
	get_tree().change_scene_to_file("res://cenas/desafio.tscn")


func _on_botao_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://cenas/menu.tscn")
