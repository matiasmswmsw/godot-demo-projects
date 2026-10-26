# aprender.gd
# Tela APRENDER: o jogador escolhe um CI e vê a pinagem desenhada, a teoria da
# porta, a tabela-verdade e como ligar o CI na protoboard.
# Também mostra as instruções de cada modo de jogo ("Como jogar").
extends Control

var modelo_atual: String = "74HC08"
var mostrando_instrucoes: bool = false

@onready var caixa_cis: VBoxContainer = $Margem/Linhas/ColunaBotoes/BotoesCIs
@onready var diagrama = $Margem/Linhas/Diagrama
@onready var texto: RichTextLabel = $Margem/Linhas/Texto
@onready var botao_como_jogar: Button = $Margem/Linhas/ColunaBotoes/BotaoComoJogar
@onready var botao_protoboard: Button = $Margem/Linhas/ColunaBotoes/BotaoProtoboard
@onready var botao_voltar: Button = $Margem/Linhas/ColunaBotoes/BotaoVoltar


func _ready() -> void:
	criar_botoes_cis()
	botao_como_jogar.pressed.connect(_on_botao_como_jogar_pressed)
	botao_protoboard.pressed.connect(_on_botao_protoboard_pressed)
	botao_voltar.pressed.connect(voltar_ao_menu)
	mostrar_ci("74HC08")


func criar_botoes_cis() -> void:
	var grupo := ButtonGroup.new()
	for porta in Global.PORTAS:
		var modelo: String = Global.CIS[porta]
		var botao := Button.new()
		botao.text = "%s  (%s)" % [modelo, porta]
		botao.toggle_mode = true
		botao.button_group = grupo
		botao.button_pressed = modelo == modelo_atual
		botao.pressed.connect(mostrar_ci.bind(modelo))
		caixa_cis.add_child(botao)


func mostrar_ci(modelo: String) -> void:
	modelo_atual = modelo
	mostrando_instrucoes = false
	botao_como_jogar.text = "Como jogar"
	diagrama.modelo = modelo
	texto.text = montar_teoria(modelo)


func _on_botao_como_jogar_pressed() -> void:
	mostrando_instrucoes = not mostrando_instrucoes
	if mostrando_instrucoes:
		texto.text = montar_instrucoes()
		botao_como_jogar.text = "Voltar à teoria"
	else:
		texto.text = montar_teoria(modelo_atual)
		botao_como_jogar.text = "Como jogar"


# Abre o Modo Livre já com a porta deste CI montada.
func _on_botao_protoboard_pressed() -> void:
	Global.porta_inicial = Global.FUNCAO_DO_CI[modelo_atual]
	get_tree().change_scene_to_file("res://cenas/modo_livre.tscn")


func montar_teoria(modelo: String) -> String:
	var porta: String = Global.FUNCAO_DO_CI[modelo]
	var portas: Array = Global.PORTAS_DO_CI[modelo]
	var porta1: Array = portas[0]
	var saida: int = porta1[porta1.size() - 1]

	var t: String = titulo("%s – porta %s" % [modelo, porta], 30)
	t += "[b]%s[/b]\n%s\n" % [Global.EXPRESSOES[porta], descricao(porta)]
	t += tabela_verdade(porta)

	t += titulo("Pinagem", 22)
	t += "• %d portas %s dentro do CI.\n" % [portas.size(), porta]
	t += "• Pino 14 = [color=#ff6b5e]VCC (+5 V)[/color] e pino 7 = [color=#80b0ff]GND[/color]. Sem os dois, o CI não funciona.\n"
	t += "• A marca (chanfro ou bolinha) mostra o lado do pino 1. A contagem segue no sentido anti-horário.\n"
	for i in range(portas.size()):
		var p: Array = portas[i]
		if p.size() == 3:
			t += "   Porta %d: entradas %d e %d → saída %d\n" % [i + 1, p[0], p[1], p[2]]
		else:
			t += "   Porta %d: entrada %d → saída %d\n" % [i + 1, p[0], p[1]]

	t += titulo("Como ligar na protoboard (porta 1)", 22)
	t += "1. Encaixe o CI atravessando o canal central, com a marca para a esquerda.\n"
	t += "2. Fio vermelho: pino 14 → trilha +.  Fio preto: pino 7 → trilha −.\n"
	if porta1.size() == 3:
		t += "3. Chave A → pino %d.  Chave B → pino %d.\n" % [porta1[0], porta1[1]]
	else:
		t += "3. Chave A → pino %d.\n" % porta1[0]
	t += "4. Pino %d (saída) → resistor de 330 Ω → perna + do LED. Perna − do LED → trilha −.\n" % saida

	t += titulo("Atenção", 22)
	t += avisos(modelo)
	t += "• No 74HC uma entrada não pode ficar solta: ela fica indefinida (nem 0 nem 1).\n"
	t += "• O LED precisa do resistor de 330 Ω (laranja, laranja, marrom). Sem ele, queima.\n"
	return t


func titulo(texto_titulo: String, tamanho: int) -> String:
	return "\n[font_size=%d][color=#f2a61a]%s[/color][/font_size]\n" % [tamanho, texto_titulo]


# Avisos que só valem para alguns CIs.
func avisos(modelo: String) -> String:
	match modelo:
		"74HC02":
			return "• Pegadinha: no 74HC02 a SAÍDA da porta 1 é o pino 1, e as entradas são os pinos 2 e 3.\n"
		"74HC04":
			return "• O 74HC04 tem 6 portas NOT, cada uma com uma entrada só.\n"
		"74HC7266":
			return "• Na linha HC a XNOR se chama 74HC7266. O antigo 74266 tinha saída em coletor aberto e precisava de um resistor de pull-up.\n"
		"74HC00":
			return "• A NAND é uma porta universal: com várias NAND dá para montar qualquer outra porta.\n"
	return ""


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


func montar_instrucoes() -> String:
	var t: String = titulo("Como jogar", 30)
	t += "[b]Controles:[/b] clique nas chaves (ou teclas A, B e C). Botão direito + arrastar gira a câmera; a roda dá zoom. Esc volta ao menu.\n"
	t += titulo("Modo Livre", 22)
	t += "Escolha a porta. A protoboard já vem montada certa. Ligue as chaves e veja o LED e a tabela-verdade.\n"
	t += titulo("Descubra a porta", 22)
	t += "O CI está escondido (74HC??). Teste as combinações e descubra a porta. 5 rodadas; acerto = 100 pontos, +50 se for em até 20 s. Quem conhece a pinagem percebe uma pista na ligação do NOR!\n"
	t += titulo("Encontre o erro", 22)
	t += "Cada montagem pode ter UM erro ou estar certa. Teste as chaves, olhe os fios e escolha a resposta na lista. 6 montagens, 100 pontos por acerto.\n"
	t += titulo("Monte o circuito", 22)
	t += "Os CIs, as chaves, os resistores e os LEDs estão no lugar. Clique num furo e depois noutro para ligar um fio. Aperte \"Testar circuito\": o jogo testa todas as combinações e compara com o pedido. Acertou? O próximo nível é liberado.\n"
	t += titulo("A protoboard", 22)
	t += "• As trilhas + (vermelha) e − (azul) estão ligadas na fonte de 5 V.\n"
	t += "• Cada coluna de 5 furos (a–e ou f–j) é ligada por dentro.\n"
	t += "• O canal central separa as duas metades: o CI fica atravessado nele.\n"
	return t


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		voltar_ao_menu()


func voltar_ao_menu() -> void:
	get_tree().change_scene_to_file("res://cenas/menu.tscn")
