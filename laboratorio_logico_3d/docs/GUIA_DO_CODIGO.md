# Guia do Código – para estudar antes da apresentação

A banca pode pedir para vocês **explicarem um trecho**, **mudarem um parâmetro** ou **fazerem uma
pequena alteração**. Este guia mostra onde está cada conceito no projeto. Leiam com o Godot aberto.

---

## 1. Ideia geral (como o programa funciona)

1. O jogo começa na cena `menu.tscn` (definida em *Projeto → Configurações → Run → Main Scene*).
2. O `Global` (`global.gd`) é um **Autoload**: fica carregado o tempo todo. Ele guarda os pontos,
   os recordes, a **pinagem dos 7 CIs** e a função `calcular_porta()`.
3. O `Circuito` (`circuito.gd`) é o **"cérebro elétrico"**: guarda o que está montado na protoboard
   (CIs, chaves, resistores, LEDs e fios) e a função `simular()` diz se cada CI está alimentado e se
   cada LED acende. Ele não desenha nada.
4. A `protoboard.tscn` (`protoboard_3d.gd`) **desenha** um Circuito em 3D e recebe os cliques. É
   reaproveitada em 4 cenas: Modo Livre, Descubra a porta, Encontre o erro e Monte o circuito.

```
[Clique na chave] -> protoboard_3d.gd muda a chave no Circuito
                  -> Circuito.simular()  (fios + pinagem + Global.calcular_porta)
                  -> LED aceso/apagado/queimado/piscando
                  -> sinal chave_alternada -> modo_livre.gd (ou outro) atualiza a tela
```

### Como funciona a simulação (`Circuito.simular()`)

1. Cada furo pertence a um **nó elétrico**. Os 5 furos de uma coluna (a–e ou f–j) são o mesmo nó;
   as trilhas + são o nó `VCC` e as trilhas − são o nó `GND` (`no_do_furo()`).
2. Fios e chaves **juntam** nós (`_unir()`). A chave ligada junta a perna do meio com o +; desligada,
   com o −.
3. O nó VCC vale 1 e o GND vale 0. Um CI só funciona se o pino 14 estiver no 1 e o pino 7 no 0
   (`_estado_alimentacao()`); invertido = queimado.
4. Cada porta lê os nós das entradas e escreve no nó da saída (`_calcular_portas_do_ci()`). Isso se
   repete num `while`, porque a saída de uma porta pode ser a entrada de outra. Entrada solta vira
   "instável" (o LED pisca), como num CI 74HC de verdade.
5. O resistor passa o nível para o LED. O LED acende com anodo = 1 e catodo = 0; sem resistor, queima.

---

## 2. Onde está cada conceito de programação

| Conceito | Onde aparece | Exemplo |
|---|---|---|
| **Variáveis e tipos** | todos os scripts | `bool` (ligada), `int` (pontos), `float` (tempo), `String` (porta), `Array` (fios), `Dictionary` (PORTAS_DO_CI), `Vector2i` (furo), `Vector3`, `Color` |
| **Constantes** | global.gd, monte_circuito.gd | `const PINO_VCC: int = 14`, `const NIVEIS` |
| **`if/elif/else`** | circuito.gd → `simular()` (LED) | aceso, queimado ou piscando |
| **`match`** | global.gd → `calcular_porta()`; encontre_erro.gd → `aplicar_defeito()` | um caso para cada porta / cada erro |
| **Laço `for`** | protoboard_3d.gd → `criar_furos()`; monte_circuito.gd → `testar_circuito()` | 420 furos; todas as combinações das chaves (`1 << n` = 2ⁿ) |
| **Laço `while`** | circuito.gd → `simular()` | repete até nenhuma porta mudar |
| **Funções com retorno** | `calcular_porta()`, `furo_do_pino()`, `simular()` | recebem parâmetros e **retornam** um valor |
| **Classe própria** | circuito.gd (`class_name Circuito`) | `Circuito.new()`, `Circuito.montagem_correta("AND")` |
| **Sinais** | protoboard_3d.gd (`chave_alternada`, `furo_clicado`), botões (`pressed`) | `.connect()` liga; `.emit()` dispara |
| **Cenas reaproveitadas** | `protoboard.tscn` instanciada em 4 cenas | |
| **Interação** | `Area3D.input_event` (chaves e furos), teclado (A, B, C, Esc), mouse (girar/zoom) | |
| **Grupos** | painel_retratil.gd (`add_to_group`), protoboard_3d.gd (`call_group`) | um botão recolhe todos os painéis de uma vez |
| **Interpolação (suavizar)** | camera_orbita.gd → `_process()` | `lerpf`, `lerp_angle`: a câmera anda aos poucos até o alvo |
| **Desenho 2D** | diagrama_ci.gd → `_draw()` | pinagem desenhada com `draw_rect`, `draw_line`, `draw_string` |
| **Troca de cena** | menu.gd → `trocar_cena()` | `get_tree().change_scene_to_file(...)` |
| **Sorteio** | desafio.gd, encontre_erro.gd | `pick_random()`, `randf()` |
| **Salvar dados** | global.gd → `salvar_dados()` / `carregar_dados()` | arquivo JSON com recordes e nível liberado |
| **Tratamento de erros** | global.gd (arquivo estragado ou que não abre), monte_circuito.gd (furo ocupado) | o jogo avisa e continua |
| **Testes** | monte_circuito.gd → `testar_circuito()` | testa todas as combinações e compara com o pedido |

---

## 3. As funções mais importantes (expliquem com suas palavras)

### `Global.calcular_porta(porta, a, b)` – global.gd
Recebe o nome da porta e as duas entradas (`true` = 1) e devolve a saída. AND → `a and b`,
OR → `a or b`, NOT → `not a`, NAND → `not (a and b)`, NOR → `not (a or b)`, XOR → `a != b`,
XNOR → `a == b`.

### `Global.PORTAS_DO_CI` – global.gd
A pinagem: para cada CI, a lista das portas, cada uma com `[entrada, entrada, saída]`.
O 74HC02 é diferente: `[2, 3, 1]` (a saída é o pino 1).

### `Circuito.furo_do_pino(ci, pino)` – circuito.gd
Diz em que furo da protoboard está cada pino. Pinos 1–7 embaixo, 8–14 em cima. Se o CI estiver
virado (`girado`), o pino 1 vai para o lugar do 8.

### `Circuito.montagem_correta(porta)` – circuito.gd
Monta a protoboard certa de uma porta: CI, chaves, resistor, LED e fios. Os pinos das entradas e da
saída vêm da tabela de pinagem.

### `aplicar_defeito()` – encontre_erro.gd
Pega a montagem certa e estraga **uma** coisa (tira um fio, inverte o LED, vira o CI...).
Retorna o furo do erro, que é marcado depois da resposta.

### `testar_circuito()` – monte_circuito.gd
Liga as chaves em todas as combinações, chama `simular()` e compara o LED com `saida_esperada()`.

---

## 4. Perguntas prováveis da banca (e respostas curtas)

- **O que é um sinal?** Um aviso que um nó manda quando algo acontece. Outros scripts se conectam a
  ele para executar uma função.
- **Por que separar `circuito.gd` e `protoboard_3d.gd`?** Um calcula (a parte elétrica), o outro
  desenha. Assim o "Monte o circuito" pode testar as combinações sem redesenhar nada.
- **Como o jogo sabe quais furos estão ligados?** Pelo nome do nó (`no_do_furo()`): furos da mesma
  coluna de 5 têm o mesmo nome; os fios juntam nós diferentes.
- **Como o clique no furo funciona?** Uma `Area3D` do tamanho da placa recebe o clique; a função
  `furo_mais_perto()` converte a posição 3D no furo.
- **Por que o LED pisca quando falta o fio da chave?** Num CI 74HC uma entrada solta fica
  indefinida; o jogo representa isso com o valor "instável".
- **O que é o Global/Autoload?** Um script sempre carregado, que guarda dados entre cenas.
- **O que é `delta`?** O tempo desde o último quadro. Somando `delta` temos um cronômetro.
- **Qual a relação com Eletrônica Digital?** Portas lógicas, tabelas-verdade, expressões booleanas,
  pinagem dos CIs 74HC, alimentação (VCC/GND), protoboard, resistor do LED, montagem de circuitos
  com várias portas (XOR com NAND, meio-somador) e análise de defeitos.

---

## 5. Alterações que a banca pode pedir (treinem!)

| Pedido | O que mudar |
|---|---|
| "Mude o número de rodadas para 3" | `desafio.gd`: `const TOTAL_RODADAS: int = 3` |
| "Dê 200 pontos por acerto" | `desafio.gd` ou `encontre_erro.gd`: `PONTOS_ACERTO` |
| "Mude o tempo do bônus" | `desafio.gd`: `const TEMPO_BONUS: float = 30.0` |
| "Mais montagens sem erro" | `encontre_erro.gd`: `CHANCE_SEM_ERRO = 0.5` |
| "Fio de sinal de outra cor" | `protoboard_3d.gd`: `CORES_FIO["sinal"]` |
| "LED verde" | `protoboard_3d.gd`: `COR_LED_ACESO` |
| "Coloque o CI em outra coluna" | `circuito.gd` → `montagem_correta()`: `adicionar_ci(modelo, 10)` (mudar também os fios) |
| "Crie um nível 6" | `monte_circuito.gd`: novo item em `NIVEIS` e um `6:` em `saida_esperada()`; em `global.gd`, `clampi(..., 1, 6)` |
| "Câmera gira mais rápido" | Inspetor do nó `PivoCamera` (cena protoboard) → `Sensibilidade` |
| "Câmera mais lenta/suave" | `PivoCamera` → `Suavidade` (menor = mais suave) |
| "Mude o texto do visor da fonte" | `protoboard_3d.gd` → `criar_fonte()`: `"5.00 V"` |
| "Recolher os painéis com outra tecla" | `protoboard_3d.gd` → `_unhandled_input`: `KEY_H` |
| "Troque a tecla da chave A para 1" | `protoboard_3d.gd` → `_unhandled_input`: `KEY_A` → `KEY_1` |
| "Mensagem diferente para 100% de acertos" | `resultado.gd` → `escolher_mensagem()` |

Dica: depois de mudar, salvem (Ctrl+S) e rodem com F5 para mostrar que funcionou.
