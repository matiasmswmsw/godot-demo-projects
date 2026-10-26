# monte_circuito.gd
# DESAFIO "MONTE O CIRCUITO": os CIs, as chaves, os resistores e os LEDs já estão
# no lugar. O jogador liga os fios (clica num furo e depois em outro) para chegar
# ao resultado pedido. São 5 níveis, cada um com mais portas lógicas juntas.
extends Node

const SEM_FURO := Vector2i(-1, -1)
const COR_CABECALHO := Color(0.2, 0.3, 0.45)
const COR_NORMAL := Color(0.15, 0.17, 0.22)
const COR_CERTO := Color(0.15, 0.5, 0.25)
const COR_ERRADO := Color(0.65, 0.15, 0.15)

# Dados de cada nível.
#   "cis":   [modelo, coluna do pino 1]
#   "leds":  [nome, coluna do anodo, fica na metade de cima?]
# As chaves ficam nas colunas 2-4, 5-7 e 8-10 (já ligadas no + e no −).
const NIVEIS: Array[Dictionary] = [
	{
		"titulo": "Nível 1 – Uma porta AND",
		"objetivo": "Ligue o 74HC08 para o LED acender só quando A = 1 e B = 1 (S = A · B).",
		"cis": [["74HC08", 12]],
		"chaves": ["A", "B"],
		"leds": [["S", 24, false]],
	},
	{
		"titulo": "Nível 2 – Duas portas em série",
		"objetivo": "Monte S = A'·B: a saída de uma NOT entra numa AND. O LED acende só com A = 0 e B = 1.",
		"cis": [["74HC04", 10], ["74HC08", 17]],
		"chaves": ["A", "B"],
		"leds": [["S", 27, false]],
	},
	{
		"titulo": "Nível 3 – Três entradas",
		"objetivo": "Monte S = A·B + C com uma AND e uma OR. Agora a tabela tem 8 linhas!",
		"cis": [["74HC08", 10], ["74HC32", 17]],
		"chaves": ["A", "B", "C"],
		"leds": [["S", 27, false]],
	},
	{
		"titulo": "Nível 4 – XOR feita só com NAND",
		"objetivo": "Use as 4 portas do 74HC00 para montar uma XOR (S = 1 quando A ≠ B).\nDica: N1 = NAND(A,B); N2 = NAND(A,N1); N3 = NAND(B,N1); S = NAND(N2,N3).",
		"cis": [["74HC00", 12]],
		"chaves": ["A", "B"],
		"leds": [["S", 24, false]],
	},
	{
		"titulo": "Nível 5 – Meio-somador",
		"objetivo": "Some A + B em binário: o LED Soma é A XOR B e o LED Vai-um é A AND B (1 + 1 = 10).",
		"cis": [["74HC86", 10], ["74HC08", 17]],
		"chaves": ["A", "B"],
		"leds": [["Soma", 27, false], ["Vai-um", 27, true]],
	},
]

var nivel: int = 1
var circuito: Circuito
var inicio_fio: Vector2i = SEM_FURO # primeiro furo do fio que está sendo ligado
var cor_fio: String = "sinal"
var botoes_nivel: Array[Button] = []

@onready var protoboard = $Protoboard
@onready var seletor_niveis: HBoxContainer = $Interface/Tela/PainelObjetivo/Coluna/SeletorNiveis
@onready var label_titulo: Label = $Interface/Tela/PainelObjetivo/Coluna/LabelTitulo
@onready var label_objetivo: Label = $Interface/Tela/PainelObjetivo/Coluna/LabelObjetivo
@onready var label_status: Label = $Interface/Tela/PainelObjetivo/Coluna/LabelStatus
@onready var tabela: GridContainer = $Interface/Tela/PainelTabela/Coluna/Tabela
@onready var label_resultado: Label = $Interface/Tela/PainelTabela/Coluna/LabelResultado
@onready var cores_fio: HBoxContainer = $Interface/Tela/Rodape/CoresFio
@onready var botao_testar: Button = $Interface/Tela/Rodape/BotaoTestar
@onready var botao_desfazer: Button = $Interface/Tela/Rodape/BotaoDesfazer
@onready var botao_limpar: Button = $Interface/Tela/Rodape/BotaoLimpar
@onready var botao_proximo: Button = $Interface/Tela/Rodape/BotaoProximo
@onready var botao_voltar: Button = $Interface/Tela/Rodape/BotaoVoltar


func _ready() -> void:
	protoboard.aceita_furos = true
	protoboard.furo_clicado.connect(_on_furo_clicado)
	criar_botoes_niveis()
	criar_botoes_cores()
	botao_testar.pressed.connect(testar_circuito)
	botao_desfazer.pressed.connect(desfazer_fio)
	botao_limpar.pressed.connect(limpar_fios)
	botao_proximo.pressed.connect(func() -> void: carregar_nivel(nivel + 1))
	botao_voltar.pressed.connect(voltar_ao_menu)
	carregar_nivel(clampi(Global.nivel_liberado, 1, NIVEIS.size()))


func criar_botoes_niveis() -> void:
	var grupo := ButtonGroup.new()
	for n in range(1, NIVEIS.size() + 1):
		var botao := Button.new()
		botao.text = "Nível %d" % n
		botao.toggle_mode = true
		botao.button_group = grupo
		botao.pressed.connect(carregar_nivel.bind(n))
		seletor_niveis.add_child(botao)
		botoes_nivel.append(botao)


func criar_botoes_cores() -> void:
	var grupo := ButtonGroup.new()
	var opcoes: Dictionary = {"vcc": "Vermelho (VCC)", "gnd": "Preto (GND)", "sinal": "Azul (sinal)"}
	for chave in opcoes:
		var botao := Button.new()
		botao.text = opcoes[chave]
		botao.toggle_mode = true
		botao.button_group = grupo
		botao.button_pressed = chave == cor_fio
		botao.pressed.connect(func() -> void: cor_fio = chave)
		cores_fio.add_child(botao)


# Monta a protoboard do nível: só as peças fixas, sem os fios do jogador.
func carregar_nivel(n: int) -> void:
	nivel = n
	var dados: Dictionary = NIVEIS[n - 1]
	circuito = Circuito.new()
	for par in dados["cis"]:
		circuito.adicionar_ci(par[0], par[1])
	for i in range(dados["chaves"].size()):
		circuito.adicionar_chave(dados["chaves"][i], 1 + 3 * i)
	circuito.ligar_chaves_na_fonte()
	for led in dados["leds"]:
		circuito.adicionar_led_com_resistor(led[0], led[1], led[2])

	inicio_fio = SEM_FURO
	protoboard.destacar_inicio(SEM_FURO)
	protoboard.carregar(circuito)
	label_titulo.text = dados["titulo"]
	label_objetivo.text = dados["objetivo"]
	label_status.text = "Clique num furo livre para começar um fio."
	label_resultado.text = "Ligue os fios e aperte \"Testar circuito\"."
	botao_proximo.visible = false
	mostrar_tabela([])
	for i in range(botoes_nivel.size()):
		botoes_nivel[i].disabled = i + 1 > Global.nivel_liberado
		botoes_nivel[i].set_pressed_no_signal(i + 1 == nivel)


# Um clique começa o fio; o segundo clique termina.
func _on_furo_clicado(furo: Vector2i) -> void:
	var ocupados: Dictionary = circuito.furos_ocupados()
	if inicio_fio == SEM_FURO:
		if ocupados.has(furo):
			label_status.text = "O furo %s já está ocupado. Use outro furo da mesma coluna." % nome_furo(furo)
			return
		inicio_fio = furo
		protoboard.destacar_inicio(furo)
		label_status.text = "Fio começa em %s. Clique onde ele termina (no mesmo furo para cancelar)." % nome_furo(furo)
	elif furo == inicio_fio:
		inicio_fio = SEM_FURO
		protoboard.destacar_inicio(SEM_FURO)
		label_status.text = "Fio cancelado."
	elif ocupados.has(furo):
		label_status.text = "O furo %s já está ocupado. Use outro furo da mesma coluna." % nome_furo(furo)
	else:
		circuito.adicionar_fio(inicio_fio, furo, cor_fio)
		label_status.text = "Fio ligado: %s → %s (%d fios seus)" % [nome_furo(inicio_fio), nome_furo(furo), contar_fios_jogador()]
		inicio_fio = SEM_FURO
		protoboard.destacar_inicio(SEM_FURO)
		protoboard.carregar(circuito)


# Nome de um furo como na protoboard de verdade: fileira + coluna (ex.: "e13").
func nome_furo(furo: Vector2i) -> String:
	return "%s%d" % [Circuito.NOMES_LINHAS[furo.y], furo.x + 1]


func contar_fios_jogador() -> int:
	var total: int = 0
	for fio in circuito.fios:
		if not fio["fixo"]:
			total += 1
	return total


func desfazer_fio() -> void:
	# Procura de trás para frente o último fio colocado pelo jogador.
	for i in range(circuito.fios.size() - 1, -1, -1):
		if not circuito.fios[i]["fixo"]:
			circuito.fios.remove_at(i)
			label_status.text = "Último fio removido."
			protoboard.carregar(circuito)
			return
	label_status.text = "Não há fios para desfazer."


func limpar_fios() -> void:
	var fixos: Array[Dictionary] = []
	for fio in circuito.fios:
		if fio["fixo"]:
			fixos.append(fio)
	circuito.fios = fixos
	label_status.text = "Todos os seus fios foram removidos."
	protoboard.carregar(circuito)


# Saída que o nível pede, para cada combinação das chaves.
func saida_esperada(entradas: Array[bool]) -> Array[bool]:
	var a: bool = entradas[0]
	var b: bool = entradas[1]
	var saidas: Array[bool] = []
	match nivel:
		1:
			saidas.append(a and b)
		2:
			saidas.append((not a) and b)
		3:
			var c: bool = entradas[2]
			saidas.append((a and b) or c)
		4:
			saidas.append(a != b)
		5:
			saidas.append(a != b) # Soma
			saidas.append(a and b) # Vai-um
	return saidas


# Transforma um número na lista de chaves ligadas. Ex.: 5 com 3 chaves → [1, 0, 1].
func bits_da_combinacao(combinacao: int, quantidade: int) -> Array[bool]:
	var entradas: Array[bool] = []
	for i in range(quantidade):
		entradas.append(((combinacao >> (quantidade - 1 - i)) & 1) == 1)
	return entradas


# Testa TODAS as combinações das chaves e compara com o pedido.
func testar_circuito() -> void:
	var quantidade: int = circuito.chaves.size()
	var guardado: Array[bool] = []
	for chave in circuito.chaves:
		guardado.append(chave["ligada"])

	var medidos: Array = []
	var problemas: Array[String] = []
	var tudo_certo: bool = true
	for combinacao in range(1 << quantidade): # 1 << n = 2 elevado a n
		var entradas: Array[bool] = bits_da_combinacao(combinacao, quantidade)
		for i in range(quantidade):
			circuito.chaves[i]["ligada"] = entradas[i]
		var res: Dictionary = circuito.simular()
		var medido: Array[bool] = []
		for estado in res["leds"]:
			medido.append(estado == "aceso")
			if estado == "queimado":
				adicionar_problema(problemas, "Um LED queimou: a saída precisa passar pelo resistor.")
			elif estado == "piscando":
				adicionar_problema(problemas, "Um LED ficou piscando: alguma entrada de porta está solta.")
		for i in range(res["cis"].size()):
			var modelo: String = circuito.cis[i]["modelo"]
			match res["cis"][i]:
				"sem_alimentacao":
					adicionar_problema(problemas, "O %s está sem alimentação: pino 14 no + e pino 7 no −." % modelo)
				"queimado":
					adicionar_problema(problemas, "O %s queimou: VCC e GND estão invertidos." % modelo)
		if res["curto_fonte"]:
			adicionar_problema(problemas, "Curto-circuito: um fio liga o + direto no −!")
		if medido != saida_esperada(entradas):
			tudo_certo = false
		medidos.append(medido)

	# Devolve as chaves como estavam.
	for i in range(quantidade):
		circuito.chaves[i]["ligada"] = guardado[i]
	protoboard.atualizar()
	mostrar_tabela(medidos)

	if tudo_certo and problemas.is_empty():
		label_resultado.text = "Circuito correto! Parabéns!"
		label_resultado.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
		if nivel < NIVEIS.size():
			Global.liberar_nivel(nivel + 1)
			botoes_nivel[nivel].disabled = false
			botao_proximo.visible = true
	else:
		var texto: String = "Ainda não. As linhas em vermelho estão diferentes do pedido."
		if not problemas.is_empty():
			texto += "\n" + "\n".join(PackedStringArray(problemas))
		label_resultado.text = texto
		label_resultado.add_theme_color_override("font_color", Color(1.0, 0.6, 0.5))


# Adiciona uma mensagem só se ela ainda não estiver na lista.
func adicionar_problema(problemas: Array[String], texto: String) -> void:
	if not problemas.has(texto):
		problemas.append(texto)


# Tabela "pedido × medido". Se medidos estiver vazio, a coluna medido mostra "?".
func mostrar_tabela(medidos: Array) -> void:
	for celula in tabela.get_children():
		celula.queue_free()
	var nomes_chaves: Array = NIVEIS[nivel - 1]["chaves"]
	var leds: Array = NIVEIS[nivel - 1]["leds"]
	tabela.columns = nomes_chaves.size() + 2 * leds.size()

	for nome in nomes_chaves:
		adicionar_celula(nome, COR_CABECALHO)
	for led in leds:
		var prefixo: String = "" if leds.size() == 1 else led[0] + "\n"
		adicionar_celula(prefixo + "pedido", COR_CABECALHO)
		adicionar_celula(prefixo + "medido", COR_CABECALHO)

	var quantidade: int = nomes_chaves.size()
	for combinacao in range(1 << quantidade):
		var entradas: Array[bool] = bits_da_combinacao(combinacao, quantidade)
		var pedido: Array[bool] = saida_esperada(entradas)
		for valor in entradas:
			adicionar_celula(Global.bit(valor), COR_NORMAL)
		for k in range(leds.size()):
			adicionar_celula(Global.bit(pedido[k]), COR_NORMAL)
			if medidos.is_empty():
				adicionar_celula("?", COR_NORMAL)
			else:
				var medido: bool = medidos[combinacao][k]
				adicionar_celula(Global.bit(medido), COR_CERTO if medido == pedido[k] else COR_ERRADO)


func adicionar_celula(texto: String, cor: Color) -> void:
	var celula := Label.new()
	celula.text = texto
	celula.custom_minimum_size = Vector2(52, 26)
	celula.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	celula.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	celula.add_theme_font_size_override("font_size", 15)
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = cor
	celula.add_theme_stylebox_override("normal", fundo)
	tabela.add_child(celula)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		voltar_ao_menu()


func voltar_ao_menu() -> void:
	get_tree().change_scene_to_file("res://cenas/menu.tscn")
