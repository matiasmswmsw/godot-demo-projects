# led.gd
# O LED representa a SAÍDA (S) do circuito.
# Aceso = nível lógico 1, apagado = nível lógico 0.
extends Node3D

var aceso: bool = false

@onready var corpo: MeshInstance3D = $Corpo
@onready var luz: OmniLight3D = $Luz
@onready var estado: Label3D = $Estado

const COR_ACESO := Color(1.0, 0.15, 0.1, 0.95)
const COR_APAGADO := Color(0.35, 0.05, 0.05, 0.85)


func _ready() -> void:
	acender(false)


# Liga ou desliga o LED.
func acender(valor: bool) -> void:
	aceso = valor
	# Corpo e Topo usam o mesmo material, então basta mudar um.
	var material: StandardMaterial3D = corpo.material_override
	material.emission_enabled = valor
	luz.visible = valor
	if valor:
		material.albedo_color = COR_ACESO
		estado.text = "1"
	else:
		material.albedo_color = COR_APAGADO
		estado.text = "0"
