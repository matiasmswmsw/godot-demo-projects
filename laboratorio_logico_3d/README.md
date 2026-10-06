# Laboratório Lógico 3D

Trabalho final de **Linguagem de Programação** (Godot), integrado com **Eletrônica Digital**.
Matias Scheid Warken e Lucas Ritter – 2º ano, Técnico em Automação Industrial, IFSul Lajeado.

Jogo/simulador 3D em que o usuário liga e desliga chaves (entradas A e B) numa bancada de
eletrônica e vê o LED (saída S) acender de acordo com a porta lógica do CI.

## Como abrir

1. Instale o **Godot 4** (versão 4.3 ou mais nova; a versão "Standard", não precisa da .NET).
2. Abra o Godot → **Importar** → selecione o arquivo `project.godot` desta pasta → **Importar e Editar**.
3. Aperte **F5** (ou o botão ▶ no canto superior direito) para rodar.

Se o Godot perguntar se quer converter o projeto para a versão nova, pode aceitar.

## Controles

| Ação | Como fazer |
|---|---|
| Ligar/desligar chave | Clique esquerdo na chave, ou teclas **A** e **B** |
| Girar a câmera | Botão direito do mouse + arrastar |
| Zoom | Roda do mouse |
| Voltar ao menu | **Esc** |

## Organização

```
laboratorio_logico_3d/
├── project.godot        configuração do projeto (cena inicial, autoload, tela)
├── tema.tres            visual dos botões e painéis
├── cenas/               cenas (.tscn)
│   ├── menu.tscn            tela inicial (3D + botões)
│   ├── modo_livre.tscn      simulador
│   ├── desafio.tscn         jogo do CI misterioso
│   ├── resultado.tscn       tela final do desafio
│   ├── como_jogar.tscn      instruções e teoria
│   ├── bancada.tscn         bancada 3D (reutilizada no Modo Livre e no Desafio)
│   ├── chave.tscn           chave/interruptor 3D clicável
│   ├── chip.tscn            CI DIP de 14 pinos
│   └── led.tscn             LED
├── scripts/             um script .gd para cada cena + global.gd
└── docs/                textos de apoio para as etapas do trabalho
    ├── ETAPA1_PROPOSTA.md
    ├── ETAPA2_ROTEIRO_TELAS.md
    └── GUIA_DO_CODIGO.md    estudem este antes da apresentação!
```
