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
	var dados: Dictionary = {"recordes": recordes, "nivel_liberado": nivel_liberado}
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
