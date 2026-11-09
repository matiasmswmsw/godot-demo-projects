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
# Ranking: as 5 melhores pontuações de cada modo, em ordem (Bubble Sort).
var rankings: Dictionary = {"descubra": [], "erro": []}
const TAMANHO_RANKING: int = 5
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
		"forca_placa": 1.0,
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

var textura_placa: ImageTexture # guardada para não desenhar de novo
var tema_da_textura: int = -1

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
	criar_sons()
	criar_ajuda()


# F1 abre/fecha a ajuda em qualquer tela.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		alternar_ajuda()


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


# Cria um ambiente (cor de fundo + luz) com as cores do tema atual.
# Sem céu: o fundo de verdade é a placa de circuito gigante (criar_fundo_placa).
func criar_ambiente() -> Environment:
	var t: Dictionary = tema()
	var ambiente := Environment.new()
	ambiente.background_mode = Environment.BG_COLOR
	ambiente.background_color = t["chao"]
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = t["ceu_horizonte"].lerp(Color.WHITE, 0.5)
	ambiente.ambient_light_energy = 0.6
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
	var dados: Dictionary = {"recordes": recordes, "rankings": rankings, "nivel_liberado": nivel_liberado, "tema": tema_atual}
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
	if typeof(dados.get("rankings")) == TYPE_DICTIONARY:
		for modo in rankings.keys():
			var lista = dados["rankings"].get(modo, [])
			if typeof(lista) == TYPE_ARRAY:
				rankings[modo] = []
				for valor in lista:
					rankings[modo].append(int(valor))
	nivel_liberado = clampi(int(dados.get("nivel_liberado", 1)), 1, 5)
	tema_atual = clampi(int(dados.get("tema", 0)), 0, TEMAS.size() - 1)


# ===================== Fundo: placa de circuito gigante =====================
# Desenha uma imagem 1024 x 1024 pixel a pixel: trilhas de cobre e pontos de solda.
# Usa sempre a mesma "semente" do sorteio, então a placa sai igual toda vez.
func textura_da_placa() -> ImageTexture:
	if textura_placa != null and tema_da_textura == tema_atual:
		return textura_placa
	var t: Dictionary = tema()
	var tamanho: int = 1024
	var imagem := Image.create(tamanho, tamanho, false, Image.FORMAT_RGB8)
	var base: Color = t["bancada"].darkened(0.45)
	imagem.fill(base)
	# Cobre "apagado": mistura a cor da trilha com o fundo para não chamar atenção.
	# A madeira já é discreta, então usa a força 1.0 (cor cheia).
	var cobre: Color = base.lerp(t["borda"], t.get("forca_placa", 0.3))
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 74 # 74 como os CIs 74HC :)
	for i in range(90): # 90 trilhas
		var x: int = sorteio.randi_range(0, tamanho / 16 - 1) * 16
		var y: int = sorteio.randi_range(0, tamanho / 16 - 1) * 16
		var passos: int = sorteio.randi_range(4, 14)
		_ponto_de_solda(imagem, x, y, cobre)
		for p in range(passos):
			var direcao: int = sorteio.randi_range(0, 3) # 0 direita, 1 baixo, 2 diagonal, 3 esquerda
			var comprimento: int = sorteio.randi_range(2, 6) * 16
			for k in range(comprimento):
				match direcao:
					0: x += 1
					1: y += 1
					2:
						x += 1
						y += 1
					3: x -= 1
				x = clampi(x, 0, tamanho - 4)
				y = clampi(y, 0, tamanho - 4)
				imagem.fill_rect(Rect2i(x, y, 2, 2), cobre) # trilha fina
		_ponto_de_solda(imagem, x, y, cobre)
	# Fileiras de furos, como as de um CI
	for linha in range(6):
		var y0: int = sorteio.randi_range(2, 60) * 16
		var x0: int = sorteio.randi_range(2, 50) * 16
		for k in range(7):
			_ponto_de_solda(imagem, x0 + k * 24, y0, cobre)
			_ponto_de_solda(imagem, x0 + k * 24, y0 + 72, cobre)
	imagem.generate_mipmaps() # versões menores: a imagem fica nítida de longe também
	textura_placa = ImageTexture.create_from_image(imagem)
	tema_da_textura = tema_atual
	return textura_placa


# Um ponto de solda: quadrado de cobre com um furo escuro no meio.
func _ponto_de_solda(imagem: Image, x: int, y: int, cobre: Color) -> void:
	var limite: int = imagem.get_width() - 12
	x = clampi(x - 4, 0, limite)
	y = clampi(y - 4, 0, limite)
	imagem.fill_rect(Rect2i(x, y, 12, 12), cobre)
	imagem.fill_rect(Rect2i(x + 4, y + 4, 4, 4), cobre.darkened(0.7))


# Um "quadro" plano gigante com a placa desenhada, para ficar atrás da cena.
func criar_fundo_placa(largura: float, altura: float) -> MeshInstance3D:
	var quadro := MeshInstance3D.new()
	var malha := QuadMesh.new()
	malha.size = Vector2(largura, altura)
	quadro.mesh = malha
	var material := StandardMaterial3D.new()
	material.albedo_texture = textura_da_placa()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED # não depende da luz
	material.uv1_scale = Vector3(largura / 8.0, altura / 8.0, 1) # repete a imagem a cada 8 unidades
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	quadro.material_override = material
	return quadro


# ===================== Ranking com Bubble Sort =====================
# Coloca a pontuação no ranking do modo atual, ordena e guarda só as 5 melhores.
# Retorna a posição (1 a 5) ou 0 se não entrou no ranking.
func adicionar_ao_ranking(pontuacao: int) -> int:
	var lista: Array = rankings[modo_atual]
	lista.append(pontuacao)
	bubble_sort_decrescente(lista)
	while lista.size() > TAMANHO_RANKING:
		lista.pop_back() # tira a menor
	salvar_dados()
	var posicao: int = lista.find(pontuacao)
	return posicao + 1 # find devolve -1 quando não acha: vira 0


# BUBBLE SORT: compara vizinhos e troca quando estão fora de ordem.
# A cada passada, o menor valor "afunda" para o fim da lista.
func bubble_sort_decrescente(lista: Array) -> void:
	var n: int = lista.size()
	for passada in range(n - 1):
		var trocou: bool = false
		for i in range(n - 1 - passada): # o fim da lista já está ordenado
			if lista[i] < lista[i + 1]:
				var temporario = lista[i]
				lista[i] = lista[i + 1]
				lista[i + 1] = temporario
				trocou = true
		if not trocou:
			break # nenhuma troca: a lista já está em ordem


# ===================== Sons (gerados por código, sem arquivos) =====================
const TAXA_AMOSTRAS: int = 22050 # amostras por segundo
var sons: Dictionary = {}
var tocador: AudioStreamPlayer


func criar_sons() -> void:
	tocador = AudioStreamPlayer.new()
	tocador.volume_db = -8.0
	add_child(tocador)
	# [frequência em Hz, duração em segundos] de cada nota
	sons["clique"] = criar_som([[1400.0, 0.03]], false)
	sons["fio"] = criar_som([[900.0, 0.05]], false)
	sons["acerto"] = criar_som([[660.0, 0.09], [880.0, 0.09], [1320.0, 0.16]], false)
	sons["erro"] = criar_som([[160.0, 0.32]], true)


# Monta um som com uma sequência de notas. quadrada = som "áspero" (onda quadrada).
func criar_som(notas: Array, quadrada: bool) -> AudioStreamWAV:
	var dados := PackedByteArray()
	for nota in notas:
		var frequencia: float = nota[0]
		var amostras: int = int(nota[1] * TAXA_AMOSTRAS)
		for i in range(amostras):
			var t: float = float(i) / TAXA_AMOSTRAS
			var onda: float = sin(TAU * frequencia * t)
			if quadrada:
				onda = signf(onda)
			var volume: float = 1.0 - float(i) / amostras # vai sumindo no fim da nota
			var valor: int = int(onda * volume * 9000.0)
			dados.append(valor & 0xFF) # 16 bits: byte de baixo...
			dados.append((valor >> 8) & 0xFF) # ...e byte de cima
	var som := AudioStreamWAV.new()
	som.format = AudioStreamWAV.FORMAT_16_BITS
	som.mix_rate = TAXA_AMOSTRAS
	som.stereo = false
	som.data = dados
	return som


func tocar_som(nome: String) -> void:
	if sons.has(nome) and tocador != null:
		tocador.stream = sons[nome]
		tocador.play()


# ===================== Ajuda (F1) =====================
var camada_ajuda: CanvasLayer


func criar_ajuda() -> void:
	camada_ajuda = CanvasLayer.new()
	camada_ajuda.layer = 100 # por cima de tudo
	camada_ajuda.visible = false
	add_child(camada_ajuda)
	var painel := PanelContainer.new()
	painel.set_anchors_preset(Control.PRESET_CENTER)
	painel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	painel.grow_vertical = Control.GROW_DIRECTION_BOTH
	camada_ajuda.add_child(painel)
	var texto := RichTextLabel.new()
	texto.bbcode_enabled = true
	texto.fit_content = true
	texto.custom_minimum_size = Vector2(620, 0)
	texto.text = """[font_size=26][b]Controles[/b][/font_size]
[b]Chaves:[/b] clique, ou teclas A, B e C
[b]Girar a câmera:[/b] botão direito + arrastar, ou setas
[b]Mover a câmera:[/b] botão do meio (ou Shift + direito) + arrastar, ou Shift + setas
[b]Zoom:[/b] roda do mouse, ou + e −
[b]Vistas prontas:[/b] 1 inclinada • 2 de cima • 3 de frente
[b]Recolher painéis:[/b] H, ou clique no título do painel
[b]Furos:[/b] passe o mouse para ver o nome e o pino do CI
[b]Monte o circuito:[/b] clique num furo e depois noutro para ligar um fio;
clique na ponta de um fio seu para removê-lo
[b]Voltar ao menu:[/b] Esc

Aperte F1 para fechar."""
	painel.add_child(texto)


func alternar_ajuda() -> void:
	camada_ajuda.visible = not camada_ajuda.visible
