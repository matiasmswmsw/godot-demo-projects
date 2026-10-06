# chip.gd
# Circuito integrado (CI) no formato DIP de 14 pinos, como os da família 74xx.
# Os pinos são criados por código, usando estruturas de repetição (for).
extends Node3D

const PINOS_POR_LADO: int = 7
const DISTANCIA_PINOS: float = 0.18

@onready var pinos: Node3D = $Pinos
@onready var rotulo: Label3D = $Rotulo


func _ready() -> void:
	criar_pinos()


func criar_pinos() -> void:
	# Malha e material compartilhados por todos os pinos.
	var malha := BoxMesh.new()
	malha.size = Vector3(0.12, 0.2, 0.06)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.8, 0.82)
	material.metallic = 1.0
	material.roughness = 0.3
	malha.material = material

	# Dois lados do CI (esquerdo = -1, direito = 1), 7 pinos em cada lado.
	for lado in [-1, 1]:
		for i in range(PINOS_POR_LADO):
			var pino := MeshInstance3D.new()
			pino.mesh = malha
			var z: float = -0.54 + i * DISTANCIA_PINOS
			pino.position = Vector3(lado * 0.44, 0.1, z)
			pinos.add_child(pino)


# Muda o texto escrito em cima do CI.
func definir_texto(texto: String) -> void:
	rotulo.text = texto
