# painel_retratil.gd
# Painel que pode ser recolhido para não esconder a protoboard.
# Coloca um botão de título em cima do painel: clicar recolhe ou abre.
# A tecla H (ou o botão "Painéis") recolhe todos de uma vez.
extends PanelContainer

@export var titulo: String = "Painel"

var recolhido: bool = false
var botao: Button
# Guarda quem estava visível antes de recolher, para devolver igual depois.
var visiveis_antes: Dictionary = {}


func _ready() -> void:
	add_to_group("paineis_retrateis")
	var coluna: Node = get_child(0)
	botao = Button.new()
	botao.flat = true
	botao.focus_mode = Control.FOCUS_NONE
	botao.alignment = HORIZONTAL_ALIGNMENT_LEFT
	botao.add_theme_font_size_override("font_size", 15)
	botao.pressed.connect(func() -> void: definir_recolhido(not recolhido))
	coluna.add_child(botao)
	coluna.move_child(botao, 0) # o botão fica em primeiro lugar
	atualizar_botao()


func definir_recolhido(valor: bool) -> void:
	if valor == recolhido:
		return
	recolhido = valor
	for filho in get_child(0).get_children():
		if filho == botao:
			continue
		if recolhido:
			visiveis_antes[filho] = filho.visible
			filho.visible = false
		else:
			filho.visible = visiveis_antes.get(filho, true)
	atualizar_botao()
	# Encolhe a altura do painel (a largura continua a mesma).
	size.y = 0


func atualizar_botao() -> void:
	if recolhido:
		botao.text = "[+] " + titulo + " (abrir)"
	else:
		botao.text = "[–] " + titulo
