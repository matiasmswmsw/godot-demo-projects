# Etapa 2 – Roteiro para desenhar as telas (à mão)

A entrega da Etapa 2 é **manuscrita**. Use este roteiro como guia para os desenhos.
Desenhem cada tela num retângulo deitado (proporção de monitor, 16:9). Escrevam o nome de cada
elemento ao lado, com setas (ex.: "botão", "título", "chave A clicável").

---

## Tela 1 – Tela inicial (Menu)

```
+--------------------------------------------------------------+
|                                                              |
|  LABORATÓRIO                         [CI 7408 girando em 3D] |
|  LÓGICO 3D          <- título                                |
|  "Aprenda as portas lógicas..."      [LED piscando]          |
|                                                              |
|  [ Modo Livre (simulador) ]   <- botão                       |
|  [ Modo Desafio (jogo)    ]   <- botão                       |
|  [ Como jogar / Teoria    ]   <- botão                       |
|  [ Sair                   ]   <- botão                       |
|  Recorde: 0 pontos                                           |
|                                        Matias e Lucas – IFSul|
+--------------------------------------------------------------+
```
Elementos: título, subtítulo, 4 botões, recorde, imagem 3D (CI + LED girando), créditos.

---

## Tela 2 – Tela principal: Modo Livre (bancada 3D)

```
+--------------------------------------------------------------+
| MODO LIVRE – Escolha a porta:           | Porta AND          |
| [AND][OR][NOT][NAND]                    | CI 7408            |
| [NOR][XOR][XNOR]                        | S = A · B          |
|                                         | A=1 B=0 -> S=0     |
|                                         | Tabela-verdade:    |
|   (A) chave    ____                     |  A | B | S         |
|    |========  |7408|  ========  (LED)   |  0 | 0 | 0         |
|   (B) chave   |AND |                    |  0 | 1 | 0         |
|    |========  |____|                    | [1 | 0 | 0] <-destaque
|                                         |  1 | 1 | 1         |
|          (mesa / protoboard em 3D)                           |
| Dicas: clique nas chaves, botão direito gira...  [Voltar]    |
+--------------------------------------------------------------+
```
Interação: clicar nos botões das portas; clicar nas chaves A e B; o LED acende ou apaga;
a linha da tabela é destacada; botão direito gira a câmera; a roda dá zoom.

---

## Tela 3 – Modo Desafio

```
+--------------------------------------------------------------+
| DESAFIO – CI misterioso                 | Suas anotações:    |
| Rodada 2 de 5                           |  A | B | S         |
| Pontos: 150                             |  0 | 0 | 1         |
| Tempo: 34.2 s                           |  0 | 1 | ?         |
|                                         |  1 | 0 | 0         |
|   (A)====   | 74?? |  ====  (LED)       |  1 | 1 | ?         |
|   (B)====   |  ?   |                    | Testadas: 2 de 4   |
|                                                              |
|     Teste as chaves e responda: qual porta está dentro do CI?|
|     [AND] [OR] [NAND] [NOR] [XOR] [XNOR]             [Menu]  |
+--------------------------------------------------------------+
```

### Tela 3b – Janela de resposta (aparece por cima após responder)
```
        +-----------------------------------+
        |  Correto! Era a porta XNOR.       |
        |  +100 pontos (+50 bônus!)         |
        |        [ Próxima rodada ]         |
        +-----------------------------------+
```
(Se errar: "Errado! Você marcou OR, mas era NOR" + expressão. Na última rodada o botão vira "Ver resultado".)

---

## Tela 4 – Resultado

```
+--------------------------------------------------------------+
|                 +---------------------------+                |
|                 |        Resultado          |                |
|                 |     Acertos: 4 de 5       |                |
|                 |     Pontos: 550           |                |
|                 |  Tempo total: 95.3 s      |                |
|                 |  "Muito bem! Revise..."   |                |
|                 |     Novo recorde!         |                |
|                 | [Jogar novamente] [Menu]  |                |
|                 +---------------------------+                |
+--------------------------------------------------------------+
```

## Tela 5 – Como jogar / Teoria

```
+--------------------------------------------------------------+
| Como jogar                                                   |
|  • Modo Livre: ...   • Modo Desafio: ...   • Câmera: ...     |
| As portas lógicas                                            |
|  AND   CI 7408 — S = A·B                                     |
|  "A saída é 1 somente quando..."   tabela A|B|S              |
|  OR ... NOT ... NAND ... NOR ... XOR ... XNOR   (rolagem)    |
|                                          [Voltar ao menu]    |
+--------------------------------------------------------------+
```

---

## Fluxo de navegação (desenhar com caixas e setas)

```
                 +--------------> Modo Livre ----------(Voltar/Esc)----+
                 |                                                     |
 Tela Inicial ---+--------------> Modo Desafio --> Resposta (x5) --> Resultado
   (Menu)    ^   |                     |                               |   |
             |   |                (Menu/Esc)                           |   |
             |   +--------------> Como jogar ---(Voltar/Esc)---+       |   |
             |   |                                             |       |   |
             |   +--------------> Sair (fecha o programa)      |       |   |
             |                                                 |       |   |
             +------------------<------------------------------+-------+   |
                                                     "Jogar novamente" -> Modo Desafio
```

Em texto: **Tela Inicial → Modo Livre → Tela Inicial**;
**Tela Inicial → Modo Desafio → Resposta (5 rodadas) → Resultado → Tela Inicial ou Modo Desafio**;
**Tela Inicial → Como Jogar → Tela Inicial**; **Tela Inicial → Sair**.
