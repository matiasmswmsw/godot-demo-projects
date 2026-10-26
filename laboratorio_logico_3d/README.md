# Laboratório Lógico 3D

Trabalho final de **Linguagem de Programação** (Godot), integrado com **Eletrônica Digital**.
Matias Scheid Warken e Lucas Ritter – 2º ano, Técnico em Automação Industrial, IFSul Lajeado.

Jogo/simulador 3D de portas lógicas montadas numa **protoboard**, com CIs da linha **74HC**
(pinagem real, VCC e GND), chaves de 3 pernas, resistor de 330 Ω e LED.

## Modos

| Modo | O que faz |
|---|---|
| **Aprender** | Pinagem desenhada dos 7 CIs, teoria, tabela-verdade e como ligar na protoboard |
| **Modo Livre** | Protoboard montada certa; o usuário liga as chaves e vê o LED e a tabela-verdade |
| **Descubra a porta** | O CI aparece como "74HC??"; testar as combinações e descobrir a porta (5 rodadas) |
| **Encontre o erro** | Montagem com um erro de ligação (ou nenhum); escolher a causa na lista (6 montagens) |
| **Monte o circuito** | CIs e LED fixos; o jogador liga os fios. 5 níveis, de uma AND até o meio-somador |

## Como abrir

1. Instale o **Godot 4** (versão 4.3 ou mais nova; a versão "Standard", não precisa da .NET).
2. Abra o Godot → **Importar** → selecione o arquivo `project.godot` desta pasta → **Importar e Editar**.
3. Aperte **F5** (ou o botão ▶ no canto superior direito) para rodar.

Se o Godot perguntar se quer converter o projeto para a versão nova, pode aceitar.

## Controles

| Ação | Como fazer |
|---|---|
| Ligar/desligar chave | Clique esquerdo na chave, ou teclas **A**, **B** e **C** |
| Ligar um fio (Monte o circuito) | Clique num furo livre e depois em outro |
| Girar a câmera | Botão direito do mouse + arrastar |
| Zoom | Roda do mouse |
| Voltar ao menu | **Esc** |

## Organização

```
laboratorio_logico_3d/
├── project.godot        configuração do projeto (cena inicial, autoload, tela)
├── tema.tres            visual dos botões e painéis
├── cenas/
│   ├── menu.tscn            tela inicial (3D + botões)
│   ├── aprender.tscn        pinagem, teoria e "como jogar"
│   ├── modo_livre.tscn      simulador
│   ├── desafio.tscn         "Descubra a porta"
│   ├── encontre_erro.tscn   "Encontre o erro"
│   ├── monte_circuito.tscn  "Monte o circuito" (níveis)
│   ├── resultado.tscn       tela final dos desafios
│   ├── protoboard.tscn      protoboard 3D (reutilizada em 4 cenas)
│   ├── chip.tscn, led.tscn  peças da vitrine do menu
├── scripts/
│   ├── global.gd            Autoload: pinagem, calcular_porta(), recordes, salvar/carregar
│   ├── circuito.gd          "cérebro elétrico": peças, fios e simular()
│   ├── protoboard_3d.gd     desenha o circuito em 3D e recebe os cliques
│   ├── diagrama_ci.gd       desenha a pinagem em 2D
│   └── um script para cada cena
└── docs/
    ├── ETAPA1_PROPOSTA.md
    ├── ETAPA2_ROTEIRO_TELAS.md
    └── GUIA_DO_CODIGO.md    estudem este antes da apresentação!
```
