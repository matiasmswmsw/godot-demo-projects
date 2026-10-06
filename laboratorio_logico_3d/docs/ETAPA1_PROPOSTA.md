# Etapa 1 – Proposta do Projeto

**1. Título do projeto:** Laboratório Lógico 3D – Descobrindo as Portas Lógicas

**2. Integrantes:** Matias Scheid Warken e Lucas Ritter – 2º ano, Técnico em Automação Industrial (IFSul – Câmpus Lajeado)

**3. Disciplina/área relacionada:** Eletrônica Digital

**4. Professor da disciplina-alvo consultado:** ______________________________

**5. Tipo de aplicação:** ☒ Jogo  ☒ Simulador  ☐ Aplicativo  ☐ Programa  ☐ Sistema interativo  ☐ Outro

**6. Qual problema, situação ou conteúdo será abordado?**
O funcionamento das portas lógicas básicas (AND, OR, NOT, NAND, NOR, XOR e XNOR) e suas tabelas-verdade.
No início da Eletrônica Digital, muitos alunos decoram as tabelas-verdade sem entender
como a saída de uma porta muda de acordo com as entradas. Montar circuitos reais para testar
todas as portas leva tempo e exige componentes (CIs da família 74xx, chaves, LEDs e protoboard).

**7. Qual é o objetivo principal da aplicação?**
Permitir que o usuário teste e aprenda o comportamento das portas lógicas de forma prática e
visual, em uma bancada de eletrônica 3D. Depois, ele coloca o conhecimento à prova em um
desafio em que precisa descobrir qual porta lógica está "escondida" dentro de um CI misterioso.

**8. Como a aplicação funcionará?**
O usuário vê uma bancada 3D com duas chaves (entradas A e B), um circuito integrado (CI) e um
LED (saída S). Ele pode girar a câmera em volta da bancada.
- **Modo Livre (simulador):** o usuário escolhe uma porta lógica e liga/desliga as chaves A e B
  clicando nelas. O LED acende (nível lógico 1) ou apaga (nível lógico 0) conforme a porta. Na tela
  aparecem a expressão booleana e a tabela-verdade, com a linha atual destacada.
- **Modo Desafio (jogo):** o CI vem marcado com "?". O usuário testa as combinações das chaves,
  observa o LED e anota os resultados. Depois escolhe qual porta acha que é. São 5 rodadas, e o
  jogo conta acertos, pontos e tempo. No final aparece a tela de resultado.

**9. Quais serão as principais funcionalidades?**
1. Bancada 3D interativa: chaves clicáveis, CI e LED que acende de acordo com a lógica da porta.
2. Modo Livre: seleção de 7 portas lógicas com expressão booleana e tabela-verdade destacada em tempo real.
3. Modo Desafio: porta lógica sorteada, registro dos testes feitos, pontuação, tempo e 5 rodadas.
4. Tela de resultado com desempenho, e tela "Como Jogar" com a explicação de cada porta.

**10. Quais conteúdos da disciplina-alvo serão utilizados?**
Níveis lógicos 0 e 1; portas lógicas AND, OR, NOT, NAND, NOR, XOR e XNOR; tabelas-verdade;
expressões booleanas (S = A·B, S = A+B, S = A' etc.); circuitos integrados da família 74xx
(7408, 7432, 7404, 7400, 7402, 7486, 74266); análise de um circuito a partir de entradas e saídas
(testar combinações para identificar a função).

**11. Como será feita a interação do usuário com a aplicação?**
Com o mouse: clique nos botões dos menus, clique nas chaves 3D para ligar/desligar, botão direito
arrastando para girar a câmera e roda do mouse para aproximar/afastar. Teclado como atalho:
teclas **A** e **B** alternam as chaves e **Esc** volta ao menu.

**Público-alvo:** estudantes de cursos técnicos (Automação, Eletrônica, Eletrotécnica) que estão
começando a estudar Eletrônica Digital.
