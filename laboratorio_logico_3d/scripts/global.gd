# global.gd
# Script "Autoload" (singleton): fica carregado o tempo todo, em todas as cenas.
# Pode ser acessado de qualquer script pelo nome "Global" (ex.: Global.pontos).
# Guarda os dados que precisam passar de uma cena para outra, os dados dos CIs
# e a função que calcula a saída das portas lógicas.
extends Node

# Lista de todas as portas lógicas que o jogo conhece.
const PORTAS: Array[String] = ["AND", "OR", "NOT", "NAND", "NOR", "XOR", "XNOR"]

# Expressão booleana de cada porta (usada nos textos da tela).
const EXPRESSOES: Dictionary = {
	"AND": "S = A · B",
	"OR": "S = A + B",
	"NOT": "S = A'",
	"NAND": "S = (A · B)'",
	"NOR": "S = (A + B)'",
	"XOR": "S = A'·B + A·B'",
	"XNOR": "S = A·B + A'·B'",
}

# Circuito integrado (CI) da linha 74HC que contém cada porta.
const CIS: Dictionary = {
	"AND": "74HC08",
	"OR": "74HC32",
	"NOT": "74HC04",
	"NAND": "74HC00",
	"NOR": "74HC02",
	"XOR": "74HC86",
	"XNOR": "74HC7266",
}

# O caminho contrário: qual porta existe dentro de cada CI.
const FUNCAO_DO_CI: Dictionary = {
	"74HC08": "AND",
	"74HC32": "OR",
	"74HC04": "NOT",
	"74HC00": "NAND",
	"74HC02": "NOR",
	"74HC86": "XOR",
	"74HC7266": "XNOR",
}

# PINAGEM: as portas que existem dentro de cada CI.
# Cada porta é uma lista de pinos: primeiro as entradas e, por último, a saída.
# Em todos estes CIs o pino 14 é o VCC (+5 V) e o pino 7 é o GND.
const PINAGEM_PADRAO: Array = [[1, 2, 3], [4, 5, 6], [9, 10, 8], [12, 13, 11]]
const PORTAS_DO_CI: Dictionary = {
	"74HC08": PINAGEM_PADRAO,
	"74HC32": PINAGEM_PADRAO,
	"74HC00": PINAGEM_PADRAO,
	"74HC86": PINAGEM_PADRAO,
	# 74HC02 (NOR): a saída vem ANTES das entradas (pegadinha!)
	"74HC02": [[2, 3, 1], [5, 6, 4], [8, 9, 10], [11, 12, 13]],
	# 74HC04 (NOT): 6 portas de uma entrada só
	"74HC04": [[1, 2], [3, 4], [5, 6], [9, 8], [11, 10], [13, 12]],
	"74HC7266": [[1, 2, 3], [5, 6, 4], [8, 9, 10], [12, 13, 11]],
}
const PINO_VCC: int = 14
const PINO_GND: int = 7

# Dados da partida atual, lidos pela tela de resultado.
var modo_atual: String = "descubra" # "descubra" ou "erro"
var pontos: int = 0
var acertos: int = 0
var total_rodadas: int = 5
var tempo_total: float = 0.0

# Porta que o Modo Livre mostra primeiro (a tela Aprender pode mudar).
var porta_inicial: String = "AND"

# Dados salvos no computador.
var recordes: Dictionary = {"descubra": 0, "erro": 0}
var nivel_liberado: int = 1 # maior nível liberado no "Monte o circuito"

# TEMAS VISUAIS: cores do céu, da bancada e da interface.
# Cada tema é um dicionário; o menu troca entre eles com o botão "Tema".
const TEMAS: Array[Dictionary] = [
	{
		"nome": "Laboratório (azul)",
		"ceu_topo": Color(0.04, 0.1, 0.22), "ceu_horizonte": Color(0.18, 0.32, 0.5), "chao": Color(0.05, 0.08, 0.14),
		"bancada": Color(0.16, 0.24, 0.36), "borda": Color(0.55, 0.75, 0.95), "manta": Color(0.06, 0.14, 0.26),
		"parede": Color(0.1, 0.18, 0.3), "letreiro": Color(0.6, 0.8, 1.0),
		"botao": Color(0.16, 0.24, 0.36), "botao_hover": Color(0.22, 0.34, 0.5), "destaque": Color(0.95, 0.65, 0.1),
		"painel": Color(0.06, 0.08, 0.12, 0.85), "painel_borda": Color(0.25, 0.4, 0.6),
	},
	{
		"nome": "Placa de circuito (verde)",
		"ceu_topo": Color(0.05, 0.18, 0.12), "ceu_horizonte": Color(0.2, 0.45, 0.3), "chao": Color(0.06, 0.12, 0.09),
		"bancada": Color(0.1, 0.32, 0.2), "borda": Color(0.75, 0.6, 0.25), "manta": Color(0.05, 0.2, 0.12),
		"parede": Color(0.08, 0.25, 0.16), "letreiro": Color(0.85, 0.7, 0.3),
		"botao": Color(0.06, 0.18, 0.11), "botao_hover": Color(0.1, 0.3, 0.18), "destaque": Color(0.9, 0.76, 0.36),
		"painel": Color(0.02, 0.08, 0.05, 0.9), "painel_borda": Color(0.18, 0.48, 0.32),
	},
	{
		"nome": "Neon (noite)",
		"ceu_topo": Color(0.04, 0.02, 0.1), "ceu_horizonte": Color(0.3, 0.05, 0.35), "chao": Color(0.05, 0.03, 0.1),
		"bancada": Color(0.12, 0.1, 0.2), "borda": Color(0.0, 0.9, 1.0), "manta": Color(0.08, 0.05, 0.15),
		"parede": Color(0.1, 0.06, 0.2), "letreiro": Color(1.0, 0.2, 0.8),
		"botao": Color(0.25, 0.08, 0.35), "botao_hover": Color(0.4, 0.12, 0.5), "destaque": Color(0.0, 0.95, 1.0),
		"painel": Color(0.05, 0.02, 0.1, 0.88), "painel_borda": Color(1.0, 0.2, 0.8),
	},
	{
		"nome": "Oficina (madeira)",
		"ceu_topo": Color(0.55, 0.62, 0.7), "ceu_horizonte": Color(0.95, 0.85, 0.7), "chao": Color(0.3, 0.25, 0.2),
		"bancada": Color(0.55, 0.38, 0.22), "borda": Color(0.3, 0.2, 0.12), "manta": Color(0.25, 0.25, 0.27),
		"parede": Color(0.9, 0.86, 0.78), "letreiro": Color(0.45, 0.25, 0.1),
		"botao": Color(0.4, 0.26, 0.14), "botao_hover": Color(0.52, 0.35, 0.2), "destaque": Color(0.95, 0.8, 0.4),
		"painel": Color(0.18, 0.12, 0.07, 0.88), "painel_borda": Color(0.75, 0.55, 0.3),
	},
	{
		"nome": "Grafite (minimalista)",
		"ceu_topo": Color(0.08, 0.08, 0.09), "ceu_horizonte": Color(0.3, 0.3, 0.32), "chao": Color(0.1, 0.1, 0.11),
		"bancada": Color(0.22, 0.22, 0.24), "borda": Color(0.85, 0.3, 0.25), "manta": Color(0.13, 0.13, 0.15),
		"parede": Color(0.18, 0.18, 0.2), "letreiro": Color(0.9, 0.35, 0.28),
		"botao": Color(0.3, 0.35, 0.42), "botao_hover": Color(0.4, 0.46, 0.55), "destaque": Color(0.9, 0.35, 0.25),
		"painel": Color(0.15, 0.17, 0.2, 0.85), "painel_borda": Color(0.85, 0.3, 0.25),
	},
]
var tema_atual: int = 1 # começa no verde (placa de circuito)

# Arquivo onde os dados ficam salvos ("user://" é uma pasta do usuário no computador).
const ARQUIVO_DADOS: String = "user://dados.json"

# Cena de cada modo de jogo (usada pelo botão "Jogar novamente").
const CENAS_DOS_MODOS: Dictionary = {
	"descubra": "res://cenas/desafio.tscn",
	"erro": "res://cenas/encontre_erro.tscn",
}


# _ready() é chamada uma vez, quando o nó fica pronto.
func _ready() -> void:
	carregar_dados()
	aplicar_tema_interface()


func tema() -> Dictionary:
	return TEMAS[tema_atual]


# Passa para o próximo tema (volta ao primeiro depois do último) e salva.
func proximo_tema() -> void:
	tema_atual = (tema_atual + 1) % TEMAS.size()
	aplicar_tema_interface()
	salvar_dados()


# Muda as cores dos botões e painéis do tema.tres (vale para todas as telas).
func aplicar_tema_interface() -> void:
	var visual: Theme = load("res://tema.tres")
	var t: Dictionary = tema()
	# Estilo "painel HUD": botões escuros com borda fina; o destaque é a cor de realce do tema.
	for estado in ["normal", "hover", "pressed"]:
		var caixa := visual.get_stylebox(estado, "Button") as StyleBoxFlat
		caixa.border_color = t["painel_borda"] if estado != "pressed" else t["destaque"]
	(visual.get_stylebox("normal", "Button") as StyleBoxFlat).bg_color = t["botao"]
	(visual.get_stylebox("hover", "Button") as StyleBoxFlat).bg_color = t["botao_hover"]
	(visual.get_stylebox("pressed", "Button") as StyleBoxFlat).bg_color = t["destaque"]
	var painel := visual.get_stylebox("panel", "PanelContainer") as StyleBoxFlat
	painel.bg_color = t["painel"]
	painel.border_color = t["painel_borda"]
	visual.emit_changed() # avisa as telas para se redesenharem


# Cria um ambiente (céu + luz) com as cores do tema atual.
func criar_ambiente() -> Environment:
	var t: Dictionary = tema()
	var material := ProceduralSkyMaterial.new()
	material.sky_top_color = t["ceu_topo"]
	material.sky_horizon_color = t["ceu_horizonte"]
	material.ground_horizon_color = t["ceu_horizonte"]
	material.ground_bottom_color = t["chao"]
	var ceu := Sky.new()
	ceu.sky_material = material
	var ambiente := Environment.new()
	ambiente.background_mode = Environment.BG_SKY
	ambiente.sky = ceu
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	ambiente.ambient_light_energy = 0.7
	ambiente.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	ambiente.glow_enabled = true
	ambiente.glow_intensity = 0.5
	return ambiente


# Calcula a saída S de uma porta lógica a partir das entradas A e B.
# true = nível lógico 1 (LED aceso), false = nível lógico 0 (LED apagado).
func calcular_porta(porta: String, a: bool, b: bool) -> bool:
	match porta:
		"AND":
			return a and b
		"OR":
			return a or b
		"NOT":
			return not a # a porta NOT só usa a entrada A
		"NAND":
			return not (a and b)
		"NOR":
			return not (a or b)
		"XOR":
			return a != b # 1 quando as entradas são diferentes
		"XNOR":
			return a == b # 1 quando as entradas são iguais
	push_error("Porta desconhecida: " + porta)
	return false


# Converte true/false para o texto "1"/"0".
func bit(valor: bool) -> String:
	if valor:
		return "1"
	return "0"


# Nome de um pino, por exemplo "1A", "1B", "1Y", "VCC" ou "GND".
# A = 1ª entrada, B = 2ª entrada, Y = saída. O número é a porta (1 a 6).
func nome_do_pino(modelo: String, pino: int) -> String:
	if pino == PINO_VCC:
		return "VCC"
	if pino == PINO_GND:
		return "GND"
	var portas: Array = PORTAS_DO_CI[modelo]
	for i in range(portas.size()):
		var porta: Array = portas[i]
		var posicao: int = porta.find(pino)
		if posicao == porta.size() - 1:
			return "%dY" % (i + 1)
		elif posicao == 0:
			return "%dA" % (i + 1)
		elif posicao == 1:
			return "%dB" % (i + 1)
	return "?"


# Zera os dados antes de começar uma nova partida.
func reiniciar_partida(modo: String, rodadas: int) -> void:
	modo_atual = modo
	total_rodadas = rodadas
	pontos = 0
	acertos = 0
	tempo_total = 0.0


# Se a pontuação for maior que o recorde do modo, salva o novo recorde.
# Retorna true quando um novo recorde foi batido.
func verificar_recorde() -> bool:
	if pontos > int(recordes.get(modo_atual, 0)):
		recordes[modo_atual] = pontos
		salvar_dados()
		return true
	return false


# Libera um nível do "Monte o circuito" e salva.
func liberar_nivel(nivel: int) -> void:
	if nivel > nivel_liberado:
		nivel_liberado = nivel
		salvar_dados()


func salvar_dados() -> void:
	var dados: Dictionary = {"recordes": recordes, "nivel_liberado": nivel_liberado, "tema": tema_atual}
	var arquivo := FileAccess.open(ARQUIVO_DADOS, FileAccess.WRITE)
	if arquivo == null:
		# Tratamento de erro: o jogo continua, só não salva.
		push_warning("Não foi possível salvar os dados: " + str(FileAccess.get_open_error()))
		return
	arquivo.store_string(JSON.stringify(dados))


func carregar_dados() -> void:
	if not FileAccess.file_exists(ARQUIVO_DADOS):
		return # primeira vez que o jogo abre: usa os valores padrão
	var arquivo := FileAccess.open(ARQUIVO_DADOS, FileAccess.READ)
	if arquivo == null:
		push_warning("Não foi possível abrir os dados salvos.")
		return
	var dados = JSON.parse_string(arquivo.get_as_text())
	# Tratamento de erro: se o arquivo estiver estragado, ignora.
	if typeof(dados) != TYPE_DICTIONARY:
		push_warning("Arquivo de dados inválido; usando valores padrão.")
		return
	if typeof(dados.get("recordes")) == TYPE_DICTIONARY:
		for modo in recordes.keys():
			recordes[modo] = int(dados["recordes"].get(modo, 0))
	nivel_liberado = clampi(int(dados.get("nivel_liberado", 1)), 1, 5)
	tema_atual = clampi(int(dados.get("tema", 0)), 0, TEMAS.size() - 1)
