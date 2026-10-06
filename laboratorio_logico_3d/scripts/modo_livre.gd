# modo_livre.gd
# MODO LIVRE (simulador): o usuário escolhe uma porta lógica e testa
# todas as combinações das chaves A e B, vendo o LED e a tabela-verdade.
extends Node

# Porta lógica selecionada no momento.
var porta_atual: String = "AND"

@onready var bancada = $Bancada
@onready var botoes_portas: GridContainer = $Interface/Tela/PainelPortas/Coluna/BotoesPortas
@onready var label_porta: Label = $Interface/Tela/PainelInfo/Coluna/LabelPorta
@onready var label_ci: Label = $Interface/Tela/PainelInfo/Coluna/LabelCI
@onready var label_expressao: Label = $Interface/Tela/PainelInfo/Coluna/LabelExpressao
@onready var label_estado: Label = $Interface/Tela/PainelInfo/Coluna/LabelEstado
@onready var tabela: GridContainer = $Interface/Tela/PainelInfo/Coluna/Tabela
@onready var botao_voltar: Button = $Interface/Tela/Rodape/BotaoVoltar


func _ready() -> void:
	criar_botoes_portas()
	bancada.entradas_mudaram.connect(_on_entradas_mudaram)
	botao_voltar.pressed.connect(voltar_ao_menu)
	selecionar_porta("AND")


# Cria um botão para cada porta da lista Global.PORTAS.
func criar_botoes_portas() -> void:
	# ButtonGroup: só um botão do grupo pode ficar "pressionado" por vez.
	var grupo := ButtonGroup.new()
	for porta in Global.PORTAS:
		var botao := Button.new()
		botao.text = porta
		botao.toggle_mode = true
		botao.button_group = grupo
		botao.custom_minimum_size = Vector2(90, 44)
		botao.button_pressed = (porta == porta_atual)
		# bind(porta) faz o botão enviar o nome da porta para a função.
		botao.pressed.connect(selecionar_porta.bind(porta))
		botoes_portas.add_child(botao)


func selecionar_porta(porta: String) -> void:
	porta_atual = porta
	label_porta.text = "Porta " + porta
	label_ci.text = "CI " + Global.CIS[porta] + " (família 74xx)"
	label_expressao.text = Global.EXPRESSOES[porta]
	bancada.mostrar_porta(porta, Global.CIS[porta])
	# A porta NOT tem só uma entrada, então a chave B é desativada.
	bancada.usar_entrada_b(porta != "NOT")
	atualizar_saida()


# Chamada pelo sinal da bancada sempre que uma chave muda.
func _on_entradas_mudaram(_a: bool, _b: bool) -> void:
	atualizar_saida()


# Calcula a saída da porta atual e atualiza o LED, o texto e a tabela.
func atualizar_saida() -> void:
	var a: bool = bancada.a
	var b: bool = bancada.b
	var s: bool = Global.calcular_porta(porta_atual, a, b)
	bancada.mostrar_saida(s)

	if porta_atual == "NOT":
		label_estado.text = "A=%s  →  S=%s" % [Global.bit(a), Global.bit(s)]
	else:
		label_estado.text = "A=%s  B=%s  →  S=%s" % [Global.bit(a), Global.bit(b), Global.bit(s)]
	montar_tabela()


# Monta a tabela-verdade da porta atual, destacando a linha das chaves.
func montar_tabela() -> void:
	# Remove as células antigas.
	for celula in tabela.get_children():
		celula.queue_free()

	# Cabeçalho.
	adicionar_celula("A", false, true)
	adicionar_celula("B", false, true)
	adicionar_celula("S", false, true)

	# Percorre todas as combinações de entradas: 00, 01, 10, 11.
	for valor_a in [false, true]:
		for valor_b in [false, true]:
			if porta_atual == "NOT" and valor_b:
				continue # a NOT só precisa de 2 linhas (A = 0 e A = 1)
			var s: bool = Global.calcular_porta(porta_atual, valor_a, valor_b)
			var linha_atual: bool = (valor_a == bancada.a and valor_b == bancada.b)
			adicionar_celula(Global.bit(valor_a), linha_atual, false)
			if porta_atual == "NOT":
				adicionar_celula("-", linha_atual, false)
			else:
				adicionar_celula(Global.bit(valor_b), linha_atual, false)
			adicionar_celula(Global.bit(s), linha_atual, false)


# Cria uma "célula" (Label com fundo colorido) dentro da tabela.
func adicionar_celula(texto: String, destacada: bool, cabecalho: bool) -> void:
	var celula := Label.new()
	celula.text = texto
	celula.custom_minimum_size = Vector2(80, 34)
	celula.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	celula.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var fundo := StyleBoxFlat.new()
	if cabecalho:
		fundo.bg_color = Color(0.2, 0.3, 0.45)
	elif destacada:
		fundo.bg_color = Color(0.95, 0.65, 0.1)
		celula.add_theme_color_override("font_color", Color.BLACK)
	else:
		fundo.bg_color = Color(0.15, 0.17, 0.22)
	celula.add_theme_stylebox_override("normal", fundo)
	tabela.add_child(celula)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # tecla Esc
		voltar_ao_menu()


func voltar_ao_menu() -> void:
	get_tree().change_scene_to_file("res://cenas/menu.tscn")
