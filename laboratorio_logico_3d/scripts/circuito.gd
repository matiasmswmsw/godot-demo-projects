# circuito.gd
# O "cérebro elétrico" da protoboard.
# Guarda o que está montado (CIs, chaves, resistores, LEDs e fios) e calcula o que
# acontece: se cada CI está alimentado e se cada LED acende.
# Este script NÃO desenha nada; quem desenha é o protoboard_3d.gd.
# "class_name" deixa usar Circuito.new() em qualquer outro script.
class_name Circuito
extends RefCounted

# ---------------------------------------------------------------------------
# Como a protoboard é organizada
# Um furo é um Vector2i(coluna, linha). Colunas de 0 a 29.
# Linhas, de cima para baixo:
#   0 = trilha + de cima       1 = trilha − de cima
#   2 a 6 = fileiras a, b, c, d, e (metade de cima)
#   7 a 11 = fileiras f, g, h, i, j (metade de baixo)
#   12 = trilha + de baixo     13 = trilha − de baixo
# A fonte de 5 V está ligada nas duas trilhas + (VCC) e nas duas trilhas − (GND).
# ---------------------------------------------------------------------------
const COLUNAS: int = 30
const LINHAS: int = 14
const NOMES_LINHAS: Array[String] = ["+", "−", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "+", "−"]
const LINHA_CHAVES: int = 3 # as chaves ficam na fileira b
const INSTAVEL: int = 2 # valor de um ponto "flutuando" (entrada solta)
const DESCONHECIDO: int = -1

var cis: Array[Dictionary] = []
var chaves: Array[Dictionary] = []
var resistores: Array[Dictionary] = []
var leds: Array[Dictionary] = []
var fios: Array[Dictionary] = []


# ===================== Montando o circuito =====================

func adicionar_ci(modelo: String, coluna: int) -> Dictionary:
	var ci: Dictionary = {
		"modelo": modelo,
		"coluna": coluna, # coluna do pino 1
		"texto": modelo, # o que aparece escrito em cima do CI
		"girado": false, # true = marca do pino 1 do lado errado
		"fora_canal": false, # true = CI não atravessa o canal central
	}
	cis.append(ci)
	return ci


# Uma chave de 3 pernas, nas colunas coluna, coluna+1 e coluna+2.
# A perna do meio é a saída. Ligada (1): meio ligado à perna da esquerda.
# Desligada (0): meio ligado à perna da direita.
func adicionar_chave(nome: String, coluna: int) -> Dictionary:
	var chave: Dictionary = {"nome": nome, "coluna": coluna, "linha": LINHA_CHAVES, "ligada": false, "ativa": true}
	chaves.append(chave)
	return chave


func adicionar_resistor(furo1: Vector2i, furo2: Vector2i) -> void:
	resistores.append({"furo1": furo1, "furo2": furo2})


func adicionar_led(nome: String, anodo: Vector2i, catodo: Vector2i) -> void:
	leds.append({"nome": nome, "anodo": anodo, "catodo": catodo})


# Coloca um resistor de 330 Ω e um LED. O anodo (+) fica na coluna indicada,
# o resistor chega nessa mesma coluna e o catodo (−) fica na coluna seguinte.
func adicionar_led_com_resistor(nome: String, coluna_anodo: int, em_cima: bool) -> void:
	var linha_led: int = 7 # fileira f
	var linha_resistor: int = 9 # fileira h
	if em_cima:
		linha_led = 6 # fileira e
		linha_resistor = 4 # fileira c
	adicionar_resistor(Vector2i(coluna_anodo - 3, linha_resistor), Vector2i(coluna_anodo, linha_resistor))
	adicionar_led(nome, Vector2i(coluna_anodo, linha_led), Vector2i(coluna_anodo + 1, linha_led))


# cor: "vcc" (vermelho), "gnd" (preto) ou "sinal".
# id: um nome para achar o fio depois (usado no "Encontre o erro").
func adicionar_fio(de: Vector2i, para: Vector2i, cor: String, fixo: bool = false, id: String = "") -> Dictionary:
	var fio: Dictionary = {"de": de, "para": para, "cor": cor, "fixo": fixo, "id": id}
	fios.append(fio)
	return fio


# Liga as pernas das pontas de todas as chaves na fonte:
# perna da esquerda no + e perna da direita no −.
func ligar_chaves_na_fonte() -> void:
	for chave in chaves:
		var c: int = chave["coluna"]
		adicionar_fio(Vector2i(c, 2), Vector2i(c, 0), "vcc", true)
		adicionar_fio(Vector2i(c + 2, 2), Vector2i(c + 2, 1), "gnd", true)


# Tira um fio pelo id (usado para criar os erros do "Encontre o erro").
func remover_fio(id: String) -> void:
	for i in range(fios.size()):
		if fios[i]["id"] == id:
			fios.remove_at(i)
			return


func fio_por_id(id: String) -> Dictionary:
	for fio in fios:
		if fio["id"] == id:
			return fio
	return {}


func chave_por_nome(nome: String) -> Dictionary:
	for chave in chaves:
		if chave["nome"] == nome:
			return chave
	return {}


# Furo onde está um pino do CI (pino de 1 a 14), visto de cima,
# com a marca do pino 1 para a esquerda: pinos 1 a 7 embaixo (da esquerda para
# a direita) e pinos 8 a 14 em cima (da direita para a esquerda).
func furo_do_pino(ci: Dictionary, pino: int) -> Vector2i:
	var p: int = pino
	if ci["girado"]:
		p = (pino + 6) % 14 + 1 # CI virado 180°: o pino 1 fica onde estaria o 8
	var coluna: int = ci["coluna"]
	var linha_baixo: int = 7 # fileira f
	var linha_cima: int = 6 # fileira e
	if ci["fora_canal"]:
		linha_baixo = 6 # os dois lados ficam na metade de cima
		linha_cima = 4
	if p <= 7:
		return Vector2i(coluna + p - 1, linha_baixo)
	return Vector2i(coluna + 14 - p, linha_cima)


# Todos os furos que já têm alguma coisa espetada.
func furos_ocupados() -> Dictionary:
	var ocupados: Dictionary = {} # usado como "conjunto": só as chaves importam
	for ci in cis:
		for pino in range(1, 15):
			ocupados[furo_do_pino(ci, pino)] = true
	for chave in chaves:
		for i in range(3):
			ocupados[Vector2i(chave["coluna"] + i, chave["linha"])] = true
	for res in resistores:
		ocupados[res["furo1"]] = true
		ocupados[res["furo2"]] = true
	for led in leds:
		ocupados[led["anodo"]] = true
		ocupados[led["catodo"]] = true
	for fio in fios:
		ocupados[fio["de"]] = true
		ocupados[fio["para"]] = true
	return ocupados


# Cria a montagem CERTA de uma porta: CI na coluna 10, chaves A e B,
# resistor de 330 Ω e LED. Usada no Modo Livre, no Desafio e no "Encontre o erro".
static func montagem_correta(porta: String) -> Circuito:
	var c := Circuito.new()
	var modelo: String = Global.CIS[porta]
	var ci: Dictionary = c.adicionar_ci(modelo, 10)
	c.adicionar_chave("A", 2)
	var chave_b: Dictionary = c.adicionar_chave("B", 5)
	c.ligar_chaves_na_fonte()
	c.adicionar_led_com_resistor("S", 23, false)

	# Alimentação do CI: pino 14 no + e pino 7 no −.
	c.adicionar_fio(c.furo_do_pino(ci, 14) + Vector2i(0, -4), Vector2i(10, 0), "vcc", true, "vcc_ci")
	c.adicionar_fio(c.furo_do_pino(ci, 7) + Vector2i(0, 4), Vector2i(16, 13), "gnd", true, "gnd_ci")

	# Usamos a porta 1 do CI. Os pinos vêm da tabela de pinagem do Global.
	var porta1: Array = Global.PORTAS_DO_CI[modelo][0]
	var pino_saida: int = porta1[porta1.size() - 1]
	# Chave A (perna do meio, fileira e) → 1ª entrada (fileira h)
	c.adicionar_fio(Vector2i(3, 6), c.furo_do_pino(ci, porta1[0]) + Vector2i(0, 2), "sinal", true, "entrada_a")
	if porta1.size() == 3:
		# Chave B (perna do meio, fileira d) → 2ª entrada (fileira i)
		c.adicionar_fio(Vector2i(6, 5), c.furo_do_pino(ci, porta1[1]) + Vector2i(0, 3), "sinal", true, "entrada_b")
	else:
		chave_b["ativa"] = false # a NOT tem uma entrada só
	# Saída (fileira j) → coluna do resistor
	c.adicionar_fio(c.furo_do_pino(ci, pino_saida) + Vector2i(0, 4), Vector2i(20, 11), "saida", true, "saida")
	# Catodo do LED → trilha −
	c.adicionar_fio(Vector2i(24, 11), Vector2i(24, 13), "gnd", true, "gnd_led")
	return c


# ===================== Simulação =====================
# Ideia: furos que estão ligados entre si formam um "nó" elétrico.
# 1) Juntamos os nós ligados por fios e pelas chaves.
# 2) O nó VCC vale 1 e o nó GND vale 0.
# 3) Cada porta de um CI alimentado lê os nós das entradas e escreve no nó da saída.
# 4) O resistor passa o nível para o LED; o LED acende se o anodo vale 1 e o catodo 0.
# Retorna um dicionário: {"cis": [estado de cada CI], "leds": [estado de cada LED], "curto_fonte": bool}
#   estado do CI:  "ok", "sem_alimentacao", "queimado" ou "curto"
#   estado do LED: "aceso", "apagado", "queimado" ou "piscando"
func simular() -> Dictionary:
	var pai: Dictionary = {} # para juntar os nós ("union-find")

	for fio in fios:
		_unir(pai, no_do_furo(fio["de"]), no_do_furo(fio["para"]))

	for chave in chaves:
		var c: int = chave["coluna"]
		var l: int = chave["linha"]
		var meio: String = no_do_furo(Vector2i(c + 1, l))
		if chave["ligada"]:
			_unir(pai, meio, no_do_furo(Vector2i(c, l)))
		else:
			_unir(pai, meio, no_do_furo(Vector2i(c + 2, l)))

	var resultado: Dictionary = {"cis": [], "leds": [], "curto_fonte": false}
	var vcc: String = _raiz(pai, "VCC")
	var gnd: String = _raiz(pai, "GND")
	if vcc == gnd:
		# + ligado direto no −: curto-circuito na fonte, nada funciona.
		resultado["curto_fonte"] = true
		for ci in cis:
			resultado["cis"].append("curto")
		for led in leds:
			resultado["leds"].append("apagado")
		return resultado

	var valor: Dictionary = {} # nó → 0, 1 ou INSTAVEL
	valor[vcc] = 1
	valor[gnd] = 0

	# Cada CI está alimentado?
	var estados: Array = []
	for ci in cis:
		estados.append(_estado_alimentacao(ci, pai, valor))
	resultado["cis"] = estados

	# Portas lógicas. Primeira passada: só valores certos (0 ou 1).
	# Segunda passada: entradas soltas viram INSTAVEL.
	for passada in range(2):
		var mudou: bool = true
		var voltas: int = 0
		while mudou and voltas < 20: # repete porque uma porta pode alimentar outra
			mudou = false
			voltas += 1
			for i in range(cis.size()):
				if estados[i] != "ok":
					continue
				if _calcular_portas_do_ci(cis[i], pai, valor, passada == 1):
					mudou = true

	# Resistores: passam o nível de um lado para o outro (limitando a corrente).
	var via_resistor: Dictionary = {}
	for res in resistores:
		var r1: String = _raiz(pai, no_do_furo(res["furo1"]))
		var r2: String = _raiz(pai, no_do_furo(res["furo2"]))
		if valor.has(r1) and not valor.has(r2):
			valor[r2] = valor[r1]
			via_resistor[r2] = true
		elif valor.has(r2) and not valor.has(r1):
			valor[r1] = valor[r2]
			via_resistor[r1] = true

	# LEDs
	for led in leds:
		var ra: String = _raiz(pai, no_do_furo(led["anodo"]))
		var rc: String = _raiz(pai, no_do_furo(led["catodo"]))
		var va: int = valor.get(ra, DESCONHECIDO)
		var vc: int = valor.get(rc, DESCONHECIDO)
		var estado: String = "apagado"
		if vc == 0 and va == 1:
			if via_resistor.has(ra):
				estado = "aceso"
			else:
				estado = "queimado" # 5 V direto no LED, sem resistor
		elif vc == 0 and va == INSTAVEL:
			estado = "piscando"
		resultado["leds"].append(estado)
	return resultado


# Nome do nó elétrico de um furo. Furos da mesma coluna de 5 (a–e ou f–j)
# estão ligados por dentro da protoboard, então têm o mesmo nome.
static func no_do_furo(furo: Vector2i) -> String:
	var linha: int = furo.y
	if linha == 0 or linha == 12:
		return "VCC"
	if linha == 1 or linha == 13:
		return "GND"
	if linha <= 6:
		return "C%d_cima" % furo.x
	return "C%d_baixo" % furo.x


func _estado_alimentacao(ci: Dictionary, pai: Dictionary, valor: Dictionary) -> String:
	if ci["fora_canal"]:
		return "curto" # os pinos dos dois lados ficam na mesma coluna
	var v14: int = valor.get(_raiz(pai, no_do_furo(furo_do_pino(ci, Global.PINO_VCC))), DESCONHECIDO)
	var v7: int = valor.get(_raiz(pai, no_do_furo(furo_do_pino(ci, Global.PINO_GND))), DESCONHECIDO)
	if v14 == 1 and v7 == 0:
		return "ok"
	if v14 == 0 and v7 == 1:
		return "queimado" # alimentação invertida
	return "sem_alimentacao"


# Calcula todas as portas de um CI. Retorna true se algum nó ganhou valor novo.
func _calcular_portas_do_ci(ci: Dictionary, pai: Dictionary, valor: Dictionary, soltas_instaveis: bool) -> bool:
	var mudou: bool = false
	var funcao: String = Global.FUNCAO_DO_CI[ci["modelo"]]
	for porta in Global.PORTAS_DO_CI[ci["modelo"]]:
		var entradas: Array[int] = []
		for k in range(porta.size() - 1):
			var no: String = _raiz(pai, no_do_furo(furo_do_pino(ci, porta[k])))
			if valor.has(no):
				entradas.append(valor[no])
			elif soltas_instaveis:
				entradas.append(INSTAVEL) # entrada solta no 74HC: valor indefinido
			else:
				entradas.append(DESCONHECIDO)
		if entradas.has(DESCONHECIDO):
			continue
		var saida: int
		if entradas.has(INSTAVEL):
			saida = INSTAVEL
		else:
			var a: bool = entradas[0] == 1
			var b: bool = entradas[entradas.size() - 1] == 1
			saida = 1 if Global.calcular_porta(funcao, a, b) else 0
		var no_saida: String = _raiz(pai, no_do_furo(furo_do_pino(ci, porta[porta.size() - 1])))
		if not valor.has(no_saida):
			valor[no_saida] = saida
			mudou = true
	return mudou


static func _raiz(pai: Dictionary, no: String) -> String:
	while pai.has(no) and pai[no] != no:
		no = pai[no]
	return no


static func _unir(pai: Dictionary, a: String, b: String) -> void:
	var ra: String = _raiz(pai, a)
	var rb: String = _raiz(pai, b)
	if ra != rb:
		pai[ra] = rb
