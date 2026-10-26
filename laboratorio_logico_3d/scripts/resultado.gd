# resultado.gd
# Tela final dos desafios ("Descubra a porta" e "Encontre o erro"):
# mostra acertos, pontos, tempo, uma mensagem e o recorde daquele modo.
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
		label_recorde.text = "Recorde atual: %d pontos" % Global.recordes[Global.modo_atual]


# Escolhe uma mensagem de acordo com o número de acertos.
func escolher_mensagem(acertos: int) -> String:
	# Porcentagem de acertos (float para não perder as casas decimais).
	var taxa: float = float(acertos) / Global.total_rodadas
	if taxa == 1.0:
		return "Excelente! Você domina as portas lógicas!"
	elif taxa >= 0.6:
		return "Muito bem! Revise o que errou na tela Aprender."
	elif taxa > 0.0:
		return "Bom começo! Treine mais no Modo Livre e na tela Aprender."
	else:
		return "Não desanime! Use o Modo Livre e a tela Aprender para estudar."


func _on_botao_novamente_pressed() -> void:
	# Volta para o mesmo modo que acabou de ser jogado.
	get_tree().change_scene_to_file(Global.CENAS_DOS_MODOS[Global.modo_atual])


func _on_botao_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://cenas/menu.tscn")
