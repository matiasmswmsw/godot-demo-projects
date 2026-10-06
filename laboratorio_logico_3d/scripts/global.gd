# global.gd
# Script "Autoload" (singleton): fica carregado o tempo todo, em todas as cenas.
# Pode ser acessado de qualquer script pelo nome "Global" (ex.: Global.pontos).
# Guarda os dados que precisam passar de uma cena para outra
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

# Circuito integrado (CI) da família 74xx que contém cada porta.
const CIS: Dictionary = {
	"AND": "7408",
	"OR": "7432",
	"NOT": "7404",
	"NAND": "7400",
	"NOR": "7402",
	"XOR": "7486",
	"XNOR": "74266",
}

# Dados do Modo Desafio, lidos pela tela de resultado.
var pontos: int = 0
var acertos: int = 0
var total_rodadas: int = 5
var tempo_total: float = 0.0
var recorde: int = 0

# Arquivo onde o recorde fica salvo ("user://" é uma pasta do usuário no computador).
const ARQUIVO_RECORDE: String = "user://recorde.txt"


# _ready() é chamada uma vez, quando o nó fica pronto.
func _ready() -> void:
	carregar_recorde()


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


# Zera os dados antes de começar um novo desafio.
func reiniciar_desafio() -> void:
	pontos = 0
	acertos = 0
	tempo_total = 0.0


# Se a pontuação for maior que o recorde, salva o novo recorde.
# Retorna true quando um novo recorde foi batido.
func verificar_recorde() -> bool:
	if pontos > recorde:
		recorde = pontos
		var arquivo := FileAccess.open(ARQUIVO_RECORDE, FileAccess.WRITE)
		if arquivo != null:
			arquivo.store_string(str(recorde))
		return true
	return false


func carregar_recorde() -> void:
	if FileAccess.file_exists(ARQUIVO_RECORDE):
		var arquivo := FileAccess.open(ARQUIVO_RECORDE, FileAccess.READ)
		if arquivo != null:
			recorde = int(arquivo.get_as_text())
