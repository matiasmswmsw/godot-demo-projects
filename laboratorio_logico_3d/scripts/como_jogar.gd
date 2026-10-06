# como_jogar.gd
# Tela de instruções e teoria. O texto das portas é gerado por código,
# usando os dados do Global e um laço (for) para montar cada tabela-verdade.
extends Control

@onready var texto: RichTextLabel = $Painel/Coluna/Texto


func _ready() -> void:
	$Painel/Coluna/BotaoVoltar.pressed.connect(voltar_ao_menu)
	texto.text = montar_texto()


func montar_texto() -> String:
	var t: String = ""
	t += "[font_size=34][color=#f2a61a]Como jogar[/color][/font_size]\n\n"
	t += "• [b]Modo Livre:[/b] escolha uma porta lógica e clique nas chaves A e B (ou use as teclas A e B). "
	t += "O LED mostra a saída S: aceso = 1, apagado = 0. A tabela-verdade destaca a combinação atual.\n"
	t += "• [b]Modo Desafio:[/b] o CI está marcado com \"?\". Teste as combinações das chaves, "
	t += "observe o LED e descubra qual porta está escondida. Acerto = %d pontos; " % 100
	t += "acertando em até 20 s você ganha +50 de bônus.\n"
	t += "• [b]Câmera:[/b] botão direito + arrastar para girar; roda do mouse para zoom. [b]Esc[/b] volta ao menu.\n\n"
	t += "[font_size=34][color=#f2a61a]As portas lógicas[/color][/font_size]\n\n"

	for porta in Global.PORTAS:
		t += "[font_size=26][b]%s[/b][/font_size]   CI %s   —   %s\n" % [
			porta, Global.CIS[porta], Global.EXPRESSOES[porta]]
		t += descricao(porta) + "\n"
		t += tabela_verdade(porta) + "\n"
	return t


# Explicação curta de cada porta.
func descricao(porta: String) -> String:
	match porta:
		"AND":
			return "A saída é 1 somente quando TODAS as entradas são 1 (\"E\")."
		"OR":
			return "A saída é 1 quando PELO MENOS UMA entrada é 1 (\"OU\")."
		"NOT":
			return "Inversora: a saída é o contrário da entrada."
		"NAND":
			return "É uma AND seguida de NOT: a saída só é 0 quando todas as entradas são 1."
		"NOR":
			return "É uma OR seguida de NOT: a saída só é 1 quando todas as entradas são 0."
		"XOR":
			return "OU exclusivo: a saída é 1 quando as entradas são DIFERENTES."
		"XNOR":
			return "Coincidência: a saída é 1 quando as entradas são IGUAIS."
	return ""


# Gera a tabela-verdade em BBCode usando dois laços "for".
func tabela_verdade(porta: String) -> String:
	var t: String = "[table=3]"
	t += "[cell][b]  A  [/b][/cell][cell][b]  B  [/b][/cell][cell][b]  S  [/b][/cell]"
	for a in [false, true]:
		for b in [false, true]:
			if porta == "NOT" and b:
				continue
			var s: bool = Global.calcular_porta(porta, a, b)
			var texto_b: String = "-" if porta == "NOT" else Global.bit(b)
			t += "[cell]  %s  [/cell][cell]  %s  [/cell][cell]  %s  [/cell]" % [
				Global.bit(a), texto_b, Global.bit(s)]
	t += "[/table]\n"
	return t


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		voltar_ao_menu()


func voltar_ao_menu() -> void:
	get_tree().change_scene_to_file("res://cenas/menu.tscn")
