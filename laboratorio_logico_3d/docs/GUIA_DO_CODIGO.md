# Guia do Código – para estudar antes da apresentação

A banca pode pedir para vocês **explicarem um trecho**, **mudarem um parâmetro** ou **fazerem uma
pequena alteração**. Este guia mostra onde está cada conceito no projeto. Leiam com o Godot aberto.

---

## 1. Ideia geral (como o programa funciona)

1. O jogo começa na cena `menu.tscn` (definida em *Projeto → Configurações → Run → Main Scene*).
2. O `Global` (script `global.gd`) é um **Autoload**: fica carregado o tempo todo e guarda
   os pontos e a função `calcular_porta()`, que é **o "cérebro" da Eletrônica Digital** do jogo.
3. A `bancada.tscn` é uma cena 3D que é **reaproveitada** no Modo Livre e no Desafio. Ela tem
   2 chaves, 1 CI e 1 LED.
4. Quando o usuário clica numa chave:
   `chave.gd` emite o sinal `alternada` → `bancada.gd` recebe e emite `entradas_mudaram` →
   `modo_livre.gd` (ou `desafio.gd`) recebe, chama `Global.calcular_porta()` e manda o resultado
   para o LED com `bancada.mostrar_saida()`.

```
[Clique na chave] -> chave.gd --sinal alternada--> bancada.gd --sinal entradas_mudaram-->
modo_livre.gd -> Global.calcular_porta(porta, a, b) -> bancada.mostrar_saida(s) -> led.gd acende/apaga
```

---

## 2. Onde está cada conceito de programação

| Conceito | Onde aparece | Exemplo |
|---|---|---|
| **Variáveis** | todos os scripts | `var porta_atual: String = "AND"` (modo_livre.gd) |
| **Tipos de dados** | | `bool` (a, b, ligada), `int` (pontos, rodada), `float` (tempo), `String` (porta), `Array` (PORTAS), `Dictionary` (EXPRESSOES, testes), `Color`, `Vector3` |
| **Constantes** | global.gd, desafio.gd | `const PONTOS_ACERTO: int = 100` |
| **Condicional `if/elif/else`** | resultado.gd → `escolher_mensagem()` | escolhe a mensagem pelo nº de acertos |
| **Condicional `match`** | global.gd → `calcular_porta()` | um caso para cada porta lógica |
| **Laço `for`** | modo_livre.gd → `montar_tabela()`; chip.gd → `criar_pinos()` | dois `for` um dentro do outro geram as 4 combinações 00, 01, 10, 11 |
| **Funções** | todos | `func calcular_porta(porta: String, a: bool, b: bool) -> bool` recebe parâmetros e **retorna** um valor |
| **Sinais (eventos)** | chave.gd (`signal alternada`), bancada.gd (`signal entradas_mudaram`), botões (`pressed`) | `.connect(funcao)` liga o sinal a uma função; `.emit()` dispara o sinal |
| **Nós** | todas as cenas | `Area3D`, `MeshInstance3D`, `Label3D`, `Camera3D`, `OmniLight3D`, `Button`, `Label`, `GridContainer`... |
| **Cenas** | pasta `cenas/` | cenas pequenas (chave, LED, chip) são **instanciadas** dentro de cenas maiores (bancada) |
| **Interação com o usuário** | chave.gd (`input_event`), camera_orbita.gd (`_unhandled_input`), botões | clique, teclado (A, B, Esc), mouse (girar/zoom) |
| **Troca de cena** | menu.gd e outros | `get_tree().change_scene_to_file("res://cenas/desafio.tscn")` |
| **Sorteio** | desafio.gd → `iniciar_rodada()` | `PORTAS_DESAFIO.pick_random()` |
| **Salvar dados em arquivo** | global.gd → `verificar_recorde()` | `FileAccess.open(...)` grava o recorde |
| **Animação** | chave.gd → `atualizar_visual()` | `create_tween()` gira a alavanca |
| **`_ready()` e `_process(delta)`** | menu.gd, desafio.gd | `_ready` roda 1 vez no início; `_process` roda a cada quadro (cronômetro, giro) |

---

## 3. As funções mais importantes (expliquem com suas palavras)

### `Global.calcular_porta(porta, a, b)` – global.gd
Recebe o nome da porta e as duas entradas (`true` = 1, `false` = 0) e devolve a saída.
- AND → `a and b` (só é 1 se as duas forem 1)
- OR → `a or b`
- NOT → `not a`
- NAND → `not (a and b)`
- NOR → `not (a or b)`
- XOR → `a != b` (1 quando são **diferentes**)
- XNOR → `a == b` (1 quando são **iguais**)

### `montar_tabela()` – modo_livre.gd
Apaga as células antigas, cria o cabeçalho e usa **dois `for`** (A = 0/1 e B = 0/1) para gerar as
4 linhas. Para cada linha, calcula S e, se a linha for igual às chaves atuais, pinta de laranja.

### `iniciar_rodada()` e `_on_resposta()` – desafio.gd
- `iniciar_rodada()` sorteia a porta secreta, zera os testes e desliga as chaves.
- `registrar_teste()` guarda cada combinação testada no **dicionário** `testes` (ex.: `"01": true`).
- `_on_resposta()` compara a resposta com a porta secreta (`if porta_escolhida == porta_secreta`),
  soma pontos (+100 e +50 de bônus se o tempo for ≤ 20 s) e mostra a janela de resultado da rodada.

### `alternar()` – chave.gd
Inverte o estado (`ligada = not ligada`), atualiza a aparência e **emite o sinal** `alternada`.

---

## 4. Perguntas prováveis da banca (e respostas curtas)

- **O que é um sinal?** Um aviso que um nó manda quando algo acontece (ex.: botão clicado). Outros
  scripts "se conectam" ao sinal para executar uma função quando ele acontece.
- **Por que a bancada é uma cena separada?** Para reaproveitar: o Modo Livre e o Desafio usam a
  mesma bancada, sem copiar código.
- **O que é o Global/Autoload?** Um script que fica sempre carregado; serve para guardar dados entre
  cenas (pontos, acertos) e funções usadas em vários lugares.
- **Como o clique na chave 3D funciona?** A chave é um `Area3D` com uma `CollisionShape3D`. O Godot
  detecta o mouse sobre a forma e dispara o sinal `input_event`; verificamos se foi botão esquerdo.
- **O que faz o `@onready`?** Pega a referência de um nó filho quando a cena fica pronta.
- **O que é `delta`?** O tempo (em segundos) que passou desde o último quadro. Somando `delta` a cada
  quadro temos um cronômetro.
- **Por que a NOT não aparece no Desafio?** Ela só tem uma entrada, então a chave B não teria efeito.
- **Qual a relação com Eletrônica Digital?** Portas lógicas, níveis lógicos 0/1, tabelas-verdade,
  expressões booleanas, CIs 74xx e o método de descobrir a função de um circuito testando entradas.

---

## 5. Alterações que a banca pode pedir (treinem!)

| Pedido | O que mudar |
|---|---|
| "Mude o número de rodadas para 3" | `global.gd`: `var total_rodadas: int = 3` |
| "Dê 200 pontos por acerto" | `desafio.gd`: `const PONTOS_ACERTO: int = 200` |
| "Mude o tempo do bônus" | `desafio.gd`: `const TEMPO_BONUS: float = 30.0` |
| "Coloque a NOT no desafio" | `desafio.gd`: adicionar `"NOT"` em `PORTAS_DESAFIO` |
| "LED verde em vez de vermelho" | `led.gd`: mudar `COR_ACESO`; e `led.tscn` → nó `Luz` → `light_color` |
| "Fio ligado de outra cor" | `bancada.gd`: `COR_FIO_LIGADO` |
| "Câmera gira mais rápido" | Inspetor do nó `PivoCamera` → `Sensibilidade` (ou `camera_orbita.gd`) |
| "Troque a tecla da chave A para 1" | `bancada.gd` → `_unhandled_input`: `KEY_A` → `KEY_1` |
| "Mensagem diferente para 5 acertos" | `resultado.gd` → `escolher_mensagem()` |
| "O LED pisca mais rápido no menu" | `menu.gd`: `INTERVALO_PISCA` |

Dica: depois de mudar, salvem (Ctrl+S) e rodem com F5 para mostrar que funcionou.
