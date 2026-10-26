# protoboard_3d.gd
# Desenha em 3D um Circuito (circuito.gd): a protoboard, os CIs, as chaves,
# os resistores, os LEDs e os fios. Quase tudo é criado por código, com laços.
# Também cuida dos cliques: nas chaves (ligar/desligar) e nos furos (ligar fios).
extends Node3D

# Avisa quando o jogador liga ou desliga uma chave.
signal chave_alternada(nome: String, ligada: bool)
# Avisa quando o jogador clica num furo (só se aceita_furos = true).
signal furo_clicado(furo: Vector2i)

const D: float = 0.12 # distância entre dois furos
# Posição (eixo Z) de cada linha da protoboard. Ver a explicação em circuito.gd.
const Z_LINHAS: Array[float] = [-1.0, -0.88, -0.66, -0.54, -0.42, -0.30, -0.18,
		0.18, 0.30, 0.42, 0.54, 0.66, 0.88, 1.0]
const SEM_FURO := Vector2i(-1, -1)

const CORES_FIO: Dictionary = {
	"vcc": Color(0.85, 0.1, 0.08),
	"gnd": Color(0.06, 0.06, 0.06),
	"sinal": Color(0.1, 0.55, 0.9),
	"saida": Color(0.95, 0.6, 0.05),
}
const COR_LED_ACESO := Color(1.0, 0.15, 0.1)
const COR_LED_APAGADO := Color(0.4, 0.06, 0.05)
const COR_LED_QUEIMADO := Color(0.12, 0.1, 0.1)

# Se true, os cliques nos furos são enviados pelo sinal furo_clicado.
var aceita_furos: bool = false
var circuito: Circuito
var resultado: Dictionary = {}

var conteudo: Node3D # tudo que é recriado quando o circuito muda
var marcador: MeshInstance3D # bolinha que mostra o furo embaixo do mouse
var marcador_inicio: MeshInstance3D # bolinha verde no começo do fio
var marcas: Array[MeshInstance3D] = [] # anéis vermelhos (erros)
var visuais_ci: Array[Dictionary] = []
var visuais_led: Array[Dictionary] = []
var visuais_chave: Array[Dictionary] = []
var tempo: float = 0.0


func _ready() -> void:
	# Liga a "seleção por raio" do mouse: sem isso, as Area3D não recebem cliques.
	get_viewport().physics_object_picking = true
	criar_placa()
	criar_furos()
	criar_rotulos()
	criar_area_de_clique()
	marcador = criar_bolinha(Color(1, 1, 1, 0.8), 0.03)
	marcador.visible = false
	marcador_inicio = criar_bolinha(Color(0.2, 1.0, 0.3), 0.035)
	marcador_inicio.visible = false
	conteudo = Node3D.new()
	add_child(conteudo)


func _process(delta: float) -> void:
	tempo += delta
	var pisca: bool = int(tempo * 6.0) % 2 == 0
	# LEDs "piscando" (entrada solta) mudam sozinhos.
	for i in range(visuais_led.size()):
		if i < resultado.get("leds", []).size() and resultado["leds"][i] == "piscando":
			pintar_led(visuais_led[i], pisca)
	# Marcas de erro piscam.
	for marca in marcas:
		marca.visible = int(tempo * 3.0) % 2 == 0


# Atalhos de teclado: A, B e C ligam e desligam as chaves.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_A:
			alternar_chave("A")
		elif event.keycode == KEY_B:
			alternar_chave("B")
		elif event.keycode == KEY_C:
			alternar_chave("C")


# ===================== Funções usadas pelas outras cenas =====================

# Recebe um circuito novo e desenha tudo de novo.
func carregar(novo: Circuito) -> void:
	circuito = novo
	limpar_marcas()
	for filho in conteudo.get_children():
		filho.queue_free()
	visuais_ci.clear()
	visuais_led.clear()
	visuais_chave.clear()

	for ci in circuito.cis:
		criar_ci(ci)
	for chave in circuito.chaves:
		criar_chave(chave)
	for res in circuito.resistores:
		criar_resistor(res)
	for led in circuito.leds:
		criar_led(led)
	for i in range(circuito.fios.size()):
		criar_fio(circuito.fios[i], i)
	atualizar()


# Simula o circuito e atualiza o visual (LEDs, CIs, chaves). Retorna o resultado.
func atualizar() -> Dictionary:
	resultado = circuito.simular()
	for i in range(visuais_led.size()):
		var estado: String = resultado["leds"][i]
		var visual: Dictionary = visuais_led[i]
		visual["aviso"].text = "QUEIMOU!" if estado == "queimado" else ""
		if estado == "queimado":
			visual["material"].albedo_color = COR_LED_QUEIMADO
			visual["material"].emission_enabled = false
			visual["luz"].visible = false
		else:
			pintar_led(visual, estado == "aceso")
	for i in range(visuais_ci.size()):
		var estado_ci: String = resultado["cis"][i]
		var visual_ci: Dictionary = visuais_ci[i]
		match estado_ci:
			"queimado":
				visual_ci["material"].albedo_color = Color(0.35, 0.05, 0.02)
				visual_ci["aviso"].text = "QUEIMOU!"
			"curto":
				visual_ci["material"].albedo_color = Color(0.12, 0.12, 0.13)
				visual_ci["aviso"].text = "CURTO!"
			_:
				visual_ci["material"].albedo_color = Color(0.12, 0.12, 0.13)
				visual_ci["aviso"].text = ""
	for visual_chave in visuais_chave:
		atualizar_chave(visual_chave)
	return resultado


func alternar_chave(nome: String) -> void:
	var chave: Dictionary = circuito.chave_por_nome(nome) if circuito else {}
	if chave.is_empty() or not chave["ativa"]:
		return
	chave["ligada"] = not chave["ligada"]
	atualizar()
	chave_alternada.emit(nome, chave["ligada"])


# Muda uma chave sem emitir o sinal (usado para reiniciar).
func definir_chave(nome: String, valor: bool) -> void:
	var chave: Dictionary = circuito.chave_por_nome(nome)
	if not chave.is_empty():
		chave["ligada"] = valor


func valor_chave(nome: String) -> bool:
	var chave: Dictionary = circuito.chave_por_nome(nome)
	return not chave.is_empty() and chave["ligada"]


func definir_texto_ci(indice: int, texto: String) -> void:
	circuito.cis[indice]["texto"] = texto
	visuais_ci[indice]["rotulo"].text = texto


# Coloca um anel vermelho piscando em volta de um furo (mostrar onde está o erro).
func marcar_furo(furo: Vector2i) -> void:
	var anel := MeshInstance3D.new()
	var malha := TorusMesh.new()
	malha.inner_radius = 0.07
	malha.outer_radius = 0.1
	anel.mesh = malha
	anel.material_override = criar_material(Color(1, 0.1, 0.1), true)
	anel.position = posicao(furo) + Vector3(0, 0.03, 0)
	add_child(anel)
	marcas.append(anel)


func limpar_marcas() -> void:
	for marca in marcas:
		marca.queue_free()
	marcas.clear()


# Mostra (ou esconde, com SEM_FURO) a bolinha verde no começo de um fio.
func destacar_inicio(furo: Vector2i) -> void:
	marcador_inicio.visible = furo != SEM_FURO
	if furo != SEM_FURO:
		marcador_inicio.position = posicao(furo) + Vector3(0, 0.03, 0)


# Posição 3D (local) de um furo.
func posicao(furo: Vector2i) -> Vector3:
	var x: float = (furo.x - (Circuito.COLUNAS - 1) / 2.0) * D
	return Vector3(x, 0.0, Z_LINHAS[furo.y])


# O contrário de posicao(): qual é o furo mais perto de um ponto?
func furo_mais_perto(ponto: Vector3) -> Vector2i:
	var coluna: int = roundi(ponto.x / D + (Circuito.COLUNAS - 1) / 2.0)
	if coluna < 0 or coluna >= Circuito.COLUNAS:
		return SEM_FURO
	var melhor_linha: int = -1
	var menor_distancia: float = 0.07 # mais longe que isso: não é furo
	for linha in range(Z_LINHAS.size()):
		var distancia: float = absf(ponto.z - Z_LINHAS[linha])
		if distancia < menor_distancia:
			menor_distancia = distancia
			melhor_linha = linha
	if melhor_linha == -1:
		return SEM_FURO
	return Vector2i(coluna, melhor_linha)


# ===================== Partes fixas (criadas uma vez) =====================

func criar_placa() -> void:
	var placa := MeshInstance3D.new()
	var malha := BoxMesh.new()
	malha.size = Vector3(Circuito.COLUNAS * D + 0.3, 0.1, 2.35)
	placa.mesh = malha
	placa.material_override = criar_material(Color(0.93, 0.93, 0.9))
	placa.position = Vector3(0, -0.05, 0)
	add_child(placa)
	# Canal central (o "rio" do meio)
	criar_caixa(self, Vector3(0, 0.001, 0), Vector3(Circuito.COLUNAS * D + 0.2, 0.004, 0.16), Color(0.8, 0.8, 0.77))
	# Faixas coloridas das trilhas: vermelha (+) e azul (−)
	var largura: float = Circuito.COLUNAS * D
	for z in [-1.07, 0.81]:
		criar_caixa(self, Vector3(0, 0.002, z), Vector3(largura, 0.004, 0.015), Color(0.85, 0.1, 0.1))
	for z in [-0.81, 1.07]:
		criar_caixa(self, Vector3(0, 0.002, z), Vector3(largura, 0.004, 0.015), Color(0.1, 0.25, 0.85))
	# Mesa embaixo de tudo
	criar_caixa(self, Vector3(0, -0.2, 0), Vector3(6.0, 0.2, 3.6), Color(0.42, 0.29, 0.18))


# Os 420 furos usam uma MultiMesh: um desenho só, repetido muitas vezes (mais leve).
func criar_furos() -> void:
	var malha := BoxMesh.new()
	malha.size = Vector3(0.045, 0.004, 0.045)
	malha.material = criar_material(Color(0.25, 0.25, 0.25))
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = malha
	multi.instance_count = Circuito.COLUNAS * Circuito.LINHAS
	var i: int = 0
	for coluna in range(Circuito.COLUNAS):
		for linha in range(Circuito.LINHAS):
			var lugar := Transform3D(Basis(), posicao(Vector2i(coluna, linha)) + Vector3(0, 0.002, 0))
			multi.set_instance_transform(i, lugar)
			i += 1
	var furos := MultiMeshInstance3D.new()
	furos.multimesh = multi
	add_child(furos)


# Letras das fileiras (a–j, + e −) do lado esquerdo e números das colunas.
func criar_rotulos() -> void:
	for linha in range(Circuito.LINHAS):
		var rotulo := criar_texto(self, Circuito.NOMES_LINHAS[linha], 48, Color(0.3, 0.3, 0.3))
		rotulo.position = posicao(Vector2i(0, linha)) + Vector3(-0.14, 0.01, 0)
	for coluna in range(0, Circuito.COLUNAS, 5):
		var numero := criar_texto(self, str(coluna + 1), 40, Color(0.45, 0.45, 0.45))
		numero.position = Vector3(posicao(Vector2i(coluna, 0)).x, 0.01, -1.12)


# Uma Area3D do tamanho da placa recebe os cliques nos furos.
func criar_area_de_clique() -> void:
	var area := Area3D.new()
	var forma := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(Circuito.COLUNAS * D + 0.2, 0.04, 2.2)
	forma.shape = caixa
	area.add_child(forma)
	add_child(area)
	area.input_event.connect(_on_area_input_event)
	area.mouse_exited.connect(func() -> void: marcador.visible = false)


func _on_area_input_event(_camera: Node, event: InputEvent, posicao_clique: Vector3, _normal: Vector3, _forma: int) -> void:
	if not aceita_furos:
		return
	var furo: Vector2i = furo_mais_perto(to_local(posicao_clique))
	marcador.visible = furo != SEM_FURO
	if furo == SEM_FURO:
		return
	marcador.position = posicao(furo) + Vector3(0, 0.02, 0)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		furo_clicado.emit(furo)


# ===================== Componentes =====================

func criar_ci(ci: Dictionary) -> void:
	var p1: Vector3 = posicao(circuito.furo_do_pino(ci, 1))
	var p14: Vector3 = posicao(circuito.furo_do_pino(ci, 14))
	var p7: Vector3 = posicao(circuito.furo_do_pino(ci, 7))
	var centro: Vector3 = (p14 + p7) / 2.0
	var largura_z: float = absf(p1.z - p14.z) - 0.06

	var corpo := criar_caixa(conteudo, centro + Vector3(0, 0.07, 0), Vector3(7 * D - 0.02, 0.08, largura_z), Color(0.12, 0.12, 0.13))
	# Pinos: um pedacinho de metal em cada furo (laço de 1 a 14)
	for pino in range(1, 15):
		var lugar: Vector3 = posicao(circuito.furo_do_pino(ci, pino))
		lugar.z = lerpf(lugar.z, centro.z, 0.15)
		criar_caixa(conteudo, lugar + Vector3(0, 0.03, 0), Vector3(0.035, 0.06, 0.03), Color(0.75, 0.75, 0.78))
	# Marca do pino 1 (chanfro): fica no lado do pino 1
	var lado: float = signf(p1.x - centro.x)
	var marca := criar_caixa(conteudo, Vector3(centro.x + lado * (3.5 * D - 0.04), centro.y + 0.112, centro.z), Vector3(0.04, 0.005, 0.08), Color(0.5, 0.5, 0.52))
	marca.name = "MarcaPino1"
	# Texto em cima do CI
	var rotulo := criar_texto(conteudo, ci["texto"], 56, Color(0.92, 0.92, 0.92))
	rotulo.position = centro + Vector3(0, 0.115, 0)
	if ci["girado"]:
		rotulo.rotation.y = PI
	var aviso := criar_texto(conteudo, "", 72, Color(1, 0.3, 0.2))
	aviso.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	aviso.position = centro + Vector3(0, 0.35, 0)
	visuais_ci.append({"material": corpo.material_override, "rotulo": rotulo, "aviso": aviso})


func criar_chave(chave: Dictionary) -> void:
	var centro: Vector3 = posicao(Vector2i(chave["coluna"] + 1, chave["linha"]))
	var area := Area3D.new()
	area.position = centro
	conteudo.add_child(area)
	criar_caixa(area, Vector3(0, 0.05, 0), Vector3(3 * D, 0.08, 0.14), Color(0.15, 0.3, 0.6))
	# A alavanca gira em volta de um "pivô" (Node3D).
	var pivo := Node3D.new()
	pivo.position = Vector3(0, 0.09, 0)
	area.add_child(pivo)
	var haste := criar_caixa(pivo, Vector3(0, 0.07, 0), Vector3(0.04, 0.14, 0.04), Color(0.8, 0.8, 0.8))
	var forma := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(3 * D + 0.04, 0.3, 0.2)
	forma.shape = caixa
	forma.position = Vector3(0, 0.12, 0)
	area.add_child(forma)
	var nome := criar_texto(area, chave["nome"], 96, Color(1, 1, 1))
	nome.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	nome.position = Vector3(0, 0.38, 0)
	var estado := criar_texto(area, "0", 72, Color(1, 1, 1))
	estado.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	estado.position = Vector3(0, 0.28, 0)

	var visual: Dictionary = {"dados": chave, "pivo": pivo, "haste": haste, "estado": estado, "area": area}
	visuais_chave.append(visual)
	# bind() faz o clique enviar o nome desta chave.
	area.input_event.connect(_on_chave_input_event.bind(chave["nome"]))
	area.mouse_entered.connect(func() -> void: area.scale = Vector3(1.08, 1.08, 1.08))
	area.mouse_exited.connect(func() -> void: area.scale = Vector3.ONE)


func _on_chave_input_event(_camera: Node, event: InputEvent, _posicao: Vector3, _normal: Vector3, _forma: int, nome: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		alternar_chave(nome)


func atualizar_chave(visual: Dictionary) -> void:
	var chave: Dictionary = visual["dados"]
	var material: StandardMaterial3D = visual["haste"].material_override
	if not chave["ativa"]:
		material.albedo_color = Color(0.4, 0.4, 0.4)
		visual["estado"].text = "-"
		visual["pivo"].rotation.z = 0.0
		return
	if chave["ligada"]:
		material.albedo_color = Color(0.2, 0.85, 0.3)
		visual["estado"].text = "1"
		visual["pivo"].rotation.z = deg_to_rad(30) # alavanca para a esquerda (+5 V)
	else:
		material.albedo_color = Color(0.85, 0.15, 0.15)
		visual["estado"].text = "0"
		visual["pivo"].rotation.z = deg_to_rad(-30) # alavanca para a direita (GND)


func criar_resistor(res: Dictionary) -> void:
	var a: Vector3 = posicao(res["furo1"])
	var b: Vector3 = posicao(res["furo2"])
	var altura := Vector3(0, 0.06, 0)
	var metal := criar_material(Color(0.7, 0.7, 0.72))
	var dentro: Vector3 = (b - a) * 0.2 # o corpo ocupa o meio (60%)
	criar_segmento(conteudo, a, a + altura, 0.008, metal)
	criar_segmento(conteudo, b, b + altura, 0.008, metal)
	criar_segmento(conteudo, a + altura, a + altura + dentro, 0.008, metal)
	criar_segmento(conteudo, b + altura, b + altura - dentro, 0.008, metal)
	criar_segmento(conteudo, a + altura + dentro, b + altura - dentro, 0.03, criar_material(Color(0.85, 0.72, 0.52)))
	# Faixas de cor de 330 Ω: laranja (3), laranja (3), marrom (×10)
	var cores: Array[Color] = [Color(1, 0.5, 0), Color(1, 0.5, 0), Color(0.45, 0.25, 0.1)]
	for i in range(cores.size()):
		var t: float = 0.3 + i * 0.13
		var centro: Vector3 = a.lerp(b, t) + altura
		criar_segmento(conteudo, centro - (b - a).normalized() * 0.008, centro + (b - a).normalized() * 0.008, 0.032, criar_material(cores[i]))


func criar_led(led: Dictionary) -> void:
	var anodo: Vector3 = posicao(led["anodo"])
	var catodo: Vector3 = posicao(led["catodo"])
	var centro: Vector3 = (anodo + catodo) / 2.0
	var metal := criar_material(Color(0.7, 0.7, 0.72))
	criar_segmento(conteudo, anodo, centro + Vector3(-0.025, 0.12, 0), 0.008, metal)
	criar_segmento(conteudo, catodo, centro + Vector3(0.025, 0.12, 0), 0.008, metal)
	var material := criar_material(COR_LED_APAGADO)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission = COR_LED_ACESO
	material.emission_energy_multiplier = 2.0
	var corpo := MeshInstance3D.new()
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = 0.05
	cilindro.bottom_radius = 0.055
	cilindro.height = 0.1
	corpo.mesh = cilindro
	corpo.material_override = material
	corpo.position = centro + Vector3(0, 0.17, 0)
	conteudo.add_child(corpo)
	var topo := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 0.05
	esfera.height = 0.1
	topo.mesh = esfera
	topo.material_override = material
	topo.position = centro + Vector3(0, 0.22, 0)
	conteudo.add_child(topo)
	var luz := OmniLight3D.new()
	luz.light_color = COR_LED_ACESO
	luz.omni_range = 0.7
	luz.light_energy = 1.5
	luz.position = centro + Vector3(0, 0.3, 0)
	conteudo.add_child(luz)
	# "+" mostra a perna do anodo (ajuda a ver se o LED está invertido)
	var mais := criar_texto(conteudo, "+", 64, Color(0.85, 0.1, 0.1))
	mais.position = anodo + Vector3(0, 0.01, 0.07)
	var nome := criar_texto(conteudo, led["nome"], 72, Color(1, 1, 1))
	nome.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	nome.position = centro + Vector3(0, 0.4, 0)
	var aviso := criar_texto(conteudo, "", 64, Color(1, 0.3, 0.2))
	aviso.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	aviso.position = centro + Vector3(0, 0.52, 0)
	visuais_led.append({"material": material, "luz": luz, "aviso": aviso})


func pintar_led(visual: Dictionary, aceso: bool) -> void:
	var material: StandardMaterial3D = visual["material"]
	material.emission_enabled = aceso
	material.albedo_color = COR_LED_ACESO if aceso else COR_LED_APAGADO
	visual["luz"].visible = aceso


# Fio em forma de "ponte": sobe, atravessa e desce.
func criar_fio(fio: Dictionary, indice: int) -> void:
	var a: Vector3 = posicao(fio["de"])
	var b: Vector3 = posicao(fio["para"])
	var altura := Vector3(0, 0.05 + (indice % 5) * 0.012, 0) # alturas diferentes para não se encostarem
	var material := criar_material(CORES_FIO.get(fio["cor"], Color.WHITE))
	criar_segmento(conteudo, a, a + altura, 0.014, material)
	criar_segmento(conteudo, a + altura, b + altura, 0.014, material)
	criar_segmento(conteudo, b + altura, b, 0.014, material)


# ===================== Ajudantes de desenho =====================

func criar_material(cor: Color, brilha: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = cor
	material.roughness = 0.6
	if brilha:
		material.emission_enabled = true
		material.emission = cor
	return material


func criar_caixa(pai: Node, lugar: Vector3, tamanho: Vector3, cor: Color) -> MeshInstance3D:
	var caixa := MeshInstance3D.new()
	var malha := BoxMesh.new()
	malha.size = tamanho
	caixa.mesh = malha
	caixa.material_override = criar_material(cor)
	caixa.position = lugar
	pai.add_child(caixa)
	return caixa


func criar_bolinha(cor: Color, raio: float) -> MeshInstance3D:
	var bolinha := MeshInstance3D.new()
	var malha := SphereMesh.new()
	malha.radius = raio
	malha.height = raio * 2.0
	bolinha.mesh = malha
	bolinha.material_override = criar_material(cor, true)
	add_child(bolinha)
	return bolinha


# Texto deitado sobre a placa (Label3D).
func criar_texto(pai: Node, texto: String, tamanho: int, cor: Color) -> Label3D:
	var rotulo := Label3D.new()
	rotulo.text = texto
	rotulo.font_size = tamanho
	rotulo.pixel_size = 0.0015
	rotulo.modulate = cor
	rotulo.outline_size = 8
	rotulo.outline_modulate = Color(0, 0, 0, 0.6)
	rotulo.rotation.x = -PI / 2.0 # deitado
	pai.add_child(rotulo)
	return rotulo


# Um cilindro fino que vai do ponto a até o ponto b (usado nos fios e pernas).
func criar_segmento(pai: Node, a: Vector3, b: Vector3, raio: float, material: StandardMaterial3D) -> void:
	var distancia: float = a.distance_to(b)
	if distancia < 0.001:
		return
	var malha := CylinderMesh.new()
	malha.top_radius = raio
	malha.bottom_radius = raio
	malha.height = distancia
	malha.radial_segments = 8
	malha.rings = 1
	var pedaco := MeshInstance3D.new()
	pedaco.mesh = malha
	pedaco.material_override = material
	pai.add_child(pedaco)
	pedaco.position = (a + b) / 2.0
	var direcao: Vector3 = (b - a).normalized()
	# O cilindro nasce "em pé" (eixo Y). Giramos para apontar de a até b.
	if absf(direcao.dot(Vector3.UP)) < 0.999:
		pedaco.basis = Basis(Quaternion(Vector3.UP, direcao))
