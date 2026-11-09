# testes.gd
# TESTES AUTOMÁTICOS: confere sozinho se as partes principais do jogo funcionam.
# Rode esta cena (F6 com ela aberta, ou o botão "Rodar testes" na tela Aprender).
# Cada teste mostra OK (verde) ou FALHOU (vermelho).
extends Control

var total: int = 0
var falhas: int = 0
var relatorio: String = ""

@onready var texto: RichTextLabel = $Margem/Coluna/Texto


func _ready() -> void:
	$Margem/Coluna/BotaoVoltar.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://cenas/menu.tscn"))
	testar_portas()
	testar_montagens()
	testar_defeitos()
	testar_niveis()
	testar_bubble_sort()
	testar_arquivo_estragado()
	var cor: String = "#66ff88" if falhas == 0 else "#ff6655"
	texto.text = "[font_size=28][color=%s]%d de %d testes passaram[/color][/font_size]\n\n%s" % [
		cor, total - falhas, total, relatorio]


# Registra o resultado de um teste.
func conferir(nome: String, passou: bool) -> void:
	total += 1
	if passou:
		relatorio += "[color=#66ff88]OK[/color]  %s\n" % nome
	else:
		falhas += 1
		relatorio += "[color=#ff6655]FALHOU[/color]  %s\n" % nome


func titulo(nome: String) -> void:
	relatorio += "\n[b]%s[/b]\n" % nome


# 1) calcular_porta() contra a tabela-verdade escrita à mão.
func testar_portas() -> void:
	titulo("Tabelas-verdade (Global.calcular_porta)")
	# Saída esperada para A,B = 00, 01, 10, 11
	var esperado: Dictionary = {
		"AND": [false, false, false, true], "OR": [false, true, true, true],
		"NAND": [true, true, true, false], "NOR": [true, false, false, false],
		"XOR": [false, true, true, false], "XNOR": [true, false, false, true],
		"NOT": [true, true, false, false],
	}
	for porta in esperado:
		var obtido: Array = []
		for a in [false, true]:
			for b in [false, true]:
				obtido.append(Global.calcular_porta(porta, a, b))
		conferir(porta, obtido == esperado[porta])


# Liga as chaves em todas as combinações e devolve o estado do LED em cada uma.
func tabela_do_led(c: Circuito) -> Array:
	var estados: Array = []
	for a in [false, true]:
		for b in [false, true]:
			c.chaves[0]["ligada"] = a
			c.chaves[1]["ligada"] = b
			estados.append(c.simular()["leds"][0])
	return estados


# 2) A montagem certa de cada porta, simulada, acende o LED igual à tabela-verdade.
func testar_montagens() -> void:
	titulo("Protoboard montada certa (Circuito.simular)")
	for porta in Global.PORTAS:
		var c := Circuito.montagem_correta(porta)
		var esperado: Array = []
		for a in [false, true]:
			for b in [false, true]:
				esperado.append("aceso" if Global.calcular_porta(porta, a, b) else "apagado")
		conferir("%s no %s" % [porta, Global.CIS[porta]], tabela_do_led(c) == esperado)


# 3) Cada defeito do "Encontre o erro" produz o sintoma certo, em todas as portas.
func testar_defeitos() -> void:
	titulo("Defeitos do Encontre o erro")
	var jogo: Node = load("res://scripts/encontre_erro.gd").new()
	for defeito in ["falta_vcc", "falta_gnd", "invertido", "girado", "entrada_solta",
			"pino_errado", "led_invertido", "sem_resistor", "fora_canal"]:
		var passou: bool = true
		for porta in Global.PORTAS:
			var c := Circuito.montagem_correta(porta)
			var certo: Array = tabela_do_led(c)
			jogo.aplicar_defeito(c, defeito)
			var leds: Array = tabela_do_led(c)
			var estado_ci: String = c.simular()["cis"][0]
			match defeito:
				"falta_vcc", "falta_gnd":
					passou = passou and estado_ci == "sem_alimentacao" and not leds.has("aceso")
				"invertido", "girado":
					passou = passou and estado_ci == "queimado"
				"fora_canal":
					passou = passou and estado_ci == "curto"
				"entrada_solta":
					passou = passou and leds.has("piscando")
				"led_invertido":
					passou = passou and not leds.has("aceso")
				"sem_resistor":
					passou = passou and leds.has("queimado")
				"pino_errado":
					passou = passou and leds != certo
		conferir(defeito, passou)
	jogo.free()


# 4) Cada nível do "Monte o circuito" tem solução: montamos a resposta e testamos.
func testar_niveis() -> void:
	titulo("Níveis do Monte o circuito (a solução funciona)")
	var jogo: Node = load("res://scripts/monte_circuito.gd").new()
	for n in range(1, 6):
		jogo.nivel = n
		var c: Circuito = montar_solucao(n, jogo.NIVEIS[n - 1])
		var passou: bool = true
		var quantidade: int = c.chaves.size()
		for combinacao in range(1 << quantidade):
			var entradas: Array[bool] = jogo.bits_da_combinacao(combinacao, quantidade)
			for i in range(quantidade):
				c.chaves[i]["ligada"] = entradas[i]
			var res: Dictionary = c.simular()
			var medido: Array[bool] = []
			for estado in res["leds"]:
				medido.append(estado == "aceso")
			passou = passou and medido == jogo.saida_esperada(entradas) and not res["cis"].has("sem_alimentacao")
		conferir("Nível %d" % n, passou)
	jogo.free()


# Monta as peças fixas do nível e liga os fios da resposta.
func montar_solucao(n: int, dados: Dictionary) -> Circuito:
	var c := Circuito.new()
	for par in dados["cis"]:
		c.adicionar_ci(par[0], par[1])
	for i in range(dados["chaves"].size()):
		c.adicionar_chave(dados["chaves"][i], 1 + 3 * i)
	c.ligar_chaves_na_fonte()
	for led in dados["leds"]:
		c.adicionar_led_com_resistor(led[0], led[1], led[2])
	for ci in c.cis: # alimentação de todos os CIs
		ligar(c, c.furo_do_pino(ci, 14), Vector2i(0, 0))
		ligar(c, c.furo_do_pino(ci, 7), Vector2i(0, 13))
	var A := Vector2i(2, 3) # perna do meio das chaves
	var B := Vector2i(5, 3)
	var x: Dictionary = c.cis[0]
	match n:
		1:
			ligar(c, A, c.furo_do_pino(x, 1)); ligar(c, B, c.furo_do_pino(x, 2))
			ligar(c, c.furo_do_pino(x, 3), Vector2i(21, 9)); ligar(c, Vector2i(25, 7), Vector2i(0, 13))
		2:
			var y: Dictionary = c.cis[1]
			ligar(c, A, c.furo_do_pino(x, 1)); ligar(c, c.furo_do_pino(x, 2), c.furo_do_pino(y, 1))
			ligar(c, B, c.furo_do_pino(y, 2)); ligar(c, c.furo_do_pino(y, 3), Vector2i(24, 9))
			ligar(c, Vector2i(28, 7), Vector2i(0, 13))
		3:
			var y: Dictionary = c.cis[1]
			ligar(c, A, c.furo_do_pino(x, 1)); ligar(c, B, c.furo_do_pino(x, 2))
			ligar(c, c.furo_do_pino(x, 3), c.furo_do_pino(y, 1)); ligar(c, Vector2i(8, 3), c.furo_do_pino(y, 2))
			ligar(c, c.furo_do_pino(y, 3), Vector2i(24, 9)); ligar(c, Vector2i(28, 7), Vector2i(0, 13))
		4: # XOR com 4 NAND
			ligar(c, A, c.furo_do_pino(x, 1)); ligar(c, A, c.furo_do_pino(x, 4))
			ligar(c, B, c.furo_do_pino(x, 2)); ligar(c, B, c.furo_do_pino(x, 9))
			ligar(c, c.furo_do_pino(x, 3), c.furo_do_pino(x, 5)); ligar(c, c.furo_do_pino(x, 3), c.furo_do_pino(x, 10))
			ligar(c, c.furo_do_pino(x, 6), c.furo_do_pino(x, 12)); ligar(c, c.furo_do_pino(x, 8), c.furo_do_pino(x, 13))
			ligar(c, c.furo_do_pino(x, 11), Vector2i(21, 9)); ligar(c, Vector2i(25, 7), Vector2i(0, 13))
		5: # meio-somador
			var y: Dictionary = c.cis[1]
			ligar(c, A, c.furo_do_pino(x, 1)); ligar(c, A, c.furo_do_pino(y, 1))
			ligar(c, B, c.furo_do_pino(x, 2)); ligar(c, B, c.furo_do_pino(y, 2))
			ligar(c, c.furo_do_pino(x, 3), Vector2i(24, 9)); ligar(c, c.furo_do_pino(y, 3), Vector2i(24, 4))
			ligar(c, Vector2i(28, 7), Vector2i(0, 13)); ligar(c, Vector2i(28, 6), Vector2i(0, 1))
	return c


# Liga um fio entre dois pontos, usando furos livres da mesma coluna (ou trilha).
func ligar(c: Circuito, a: Vector2i, b: Vector2i) -> void:
	c.adicionar_fio(furo_livre(c, a), furo_livre(c, b), "sinal")


func furo_livre(c: Circuito, furo: Vector2i) -> Vector2i:
	var ocupados: Dictionary = c.furos_ocupados()
	var candidatos: Array[Vector2i] = []
	if furo.y in [0, 1, 12, 13]:
		for coluna in range(Circuito.COLUNAS):
			candidatos.append(Vector2i(coluna, furo.y))
	else:
		var primeira: int = 2 if furo.y <= 6 else 7
		for linha in range(primeira, primeira + 5):
			candidatos.append(Vector2i(furo.x, linha))
	for candidato in candidatos:
		if not ocupados.has(candidato):
			return candidato
	push_error("Sem furo livre perto de %s" % furo)
	return furo


# 5) O Bubble Sort do ranking ordena do maior para o menor.
func testar_bubble_sort() -> void:
	titulo("Ranking (Bubble Sort)")
	var lista: Array = [300, 750, 100, 550, 600]
	Global.bubble_sort_decrescente(lista)
	conferir("ordena [300, 750, 100, 550, 600]", lista == [750, 600, 550, 300, 100])
	var vazia: Array = []
	Global.bubble_sort_decrescente(vazia)
	conferir("lista vazia não dá erro", vazia.is_empty())


# 6) Tratamento de erro: um arquivo de dados estragado não pode travar o jogo.
func testar_arquivo_estragado() -> void:
	titulo("Tratamento de erros")
	var dados = JSON.parse_string("isso não é JSON {{")
	conferir("texto inválido vira null (o jogo usa os valores padrão)", dados == null)
	conferir("pino 14 se chama VCC", Global.nome_do_pino("74HC08", 14) == "VCC")
	conferir("74HC02: pino 1 é a saída (1Y)", Global.nome_do_pino("74HC02", 1) == "1Y")
