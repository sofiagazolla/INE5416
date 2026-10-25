:- use_module(library(clpfd)).


% entrada do puzzle: matriz com celulas brancas (x),
% pretas com pista de soma (p(S)) e pretas sem pista (p)
puzzle([
    [x, x, x, x, x, p(5), p(1), p(1)],
    [x, x, x, x, p(21), p(17), p(10), x],
    [p(12), x, p(24), x, x, x, x, p(7)],
    [x, p(13), x, x, p(21), x, p(17), x],
    [p(11), x, x, x, x, p(16), x, p(13)],
    [x, p(18), p(11), p(13), x, x, x, x],
    [x, p(15), x, p(8), p(12), x, x, x],
    [p(5), x, p(6), p(7), x, x, x, x]
]).


% monta a grade de variaveis no mesmo formato do puzzle
% celula branca vira variavel de 1 ate N
% celula preta vira 0 p nao atrapalhar as somas
montar_grade([], _, []).
montar_grade([LinhaP | RestoP], N, [LinhaV | RestoV]) :-
    montar_linha(LinhaP, N, LinhaV),
    montar_grade(RestoP, N, RestoV).

montar_linha([], _, []).
montar_linha([x | Resto], N, [V | RestoV]) :-
    V in 1..N,
    montar_linha(Resto, N, RestoV).
montar_linha([p | Resto], N, [0 | RestoV]) :-
    montar_linha(Resto, N, RestoV).
montar_linha([p(_) | Resto], N, [0 | RestoV]) :-
    montar_linha(Resto, N, RestoV).


% conta qtas celulas brancas tem na primeira linha p descobrir o N do puzzle
contar_brancas([], 0).
contar_brancas([x | Resto], N) :-
    contar_brancas(Resto, N1),
    N is N1 + 1.
contar_brancas([p | Resto], N) :-
    contar_brancas(Resto, N).
contar_brancas([p(_) | Resto], N) :-
    contar_brancas(Resto, N).


% separa so as variaveis das celulas brancas de uma linha
brancas([], [], []).
brancas([x | RestoP], [V | RestoV], [V | Vs]) :-
    brancas(RestoP, RestoV, Vs).
brancas([p | RestoP], [_ | RestoV], Vs) :-
    brancas(RestoP, RestoV, Vs).
brancas([p(_) | RestoP], [_ | RestoV], Vs) :-
    brancas(RestoP, RestoV, Vs).


% garante que os numeros das celulas brancas nao se repetem em cada linha
diferentes_por_linha([], []).
diferentes_por_linha([LinhaP | RestoP], [LinhaV | RestoV]) :-
    brancas(LinhaP, LinhaV, Vs),
    all_different(Vs),
    diferentes_por_linha(RestoP, RestoV).


% os 8 deslocamentos (linha, coluna) p chegar nas celulas vizinhas
deslocamentos([-1-(-1), -1-0, -1-1, 0-(-1), 0-1, 1-(-1), 1-0, 1-1]).


% pega o valor da celula (I,J)
% se tiver fora do tabuleiro, devolve 0 p nao interferir na soma
valor_celula(Grade, T, I, J, V) :-
    I >= 0, I < T, J >= 0, J < T,
    nth0(I, Grade, Linha),
    nth0(J, Linha, V).
valor_celula(_, T, I, J, 0) :-
    ( I < 0 ; I >= T ; J < 0 ; J >= T ).


% junta os valores das 8 celulas vizinhas ao redor de (I,J)
vizinhos(Grade, T, I, J, Vs) :-
    deslocamentos(Ds),
    valores_vizinhos(Ds, Grade, T, I, J, Vs).

valores_vizinhos([], _, _, _, _, []).
valores_vizinhos([DI-DJ | Resto], Grade, T, I, J, [V | Vs]) :-
    I2 is I + DI,
    J2 is J + DJ,
    valor_celula(Grade, T, I2, J2, V),
    valores_vizinhos(Resto, Grade, T, I, J, Vs).


% percorre o puzzle linha por linha gerando as restricoes de soma
somas_por_linha([], _, _, _).
somas_por_linha([LinhaP | RestoP], Grade, T, I) :-
    somas_na_linha(LinhaP, Grade, T, I, 0),
    I2 is I + 1,
    somas_por_linha(RestoP, Grade, T, I2).


% percorre cada celula da linha
% so as celulas pretas com pista de soma criam restricao
somas_na_linha([], _, _, _, _).
somas_na_linha([x | Resto], Grade, T, I, J) :-
    J2 is J + 1,
    somas_na_linha(Resto, Grade, T, I, J2).
somas_na_linha([p | Resto], Grade, T, I, J) :-
    J2 is J + 1,
    somas_na_linha(Resto, Grade, T, I, J2).
somas_na_linha([p(S) | Resto], Grade, T, I, J) :-
    vizinhos(Grade, T, I, J, Vs),
    sum(Vs, #=, S),
    J2 is J + 1,
    somas_na_linha(Resto, Grade, T, I, J2).


% resolve o puzzle: calcula N, cria variaveis, aplica restricoes e busca a solucao
resolver(Puzzle, Grade) :-
    length(Puzzle, T),
    Puzzle = [PrimeiraLinha | _],
    contar_brancas(PrimeiraLinha, N),
    montar_grade(Puzzle, N, Grade),

    % garante numeros diferentes por linha
    diferentes_por_linha(Puzzle, Grade),

    % garante numeros diferentes por coluna usando a grade transposta
    transpose(Puzzle, PuzzleT),
    transpose(Grade, GradeT),
    diferentes_por_linha(PuzzleT, GradeT),

    % aplica a regra da soma dos vizinhos das celulas pretas
    somas_por_linha(Puzzle, Grade, T, 0),

    % faz a busca dos valores (ff escolhe primeiro as variaveis com menos opcoes)
    append(Grade, Todas),
    labeling([ff], Todas).


% imprime o tabuleiro completo no terminal
imprimir_grade([], []).
imprimir_grade([LinhaP | RestoP], [LinhaV | RestoV]) :-
    imprimir_linha(LinhaP, LinhaV),
    nl,
    imprimir_grade(RestoP, RestoV).

imprimir_linha([], []).
imprimir_linha([CelulaP | RestoP], [V | RestoV]) :-
    texto_celula(CelulaP, V, Texto),
    escrever_largura(Texto, 6),
    imprimir_linha(RestoP, RestoV).


% formata o texto de cada celula (numero p branca, [S] ou [ ] p preta)
texto_celula(x, V, Texto) :-
    format(atom(Texto), "~w", [V]).
texto_celula(p, _, '[ ]').
texto_celula(p(S), _, Texto) :-
    format(atom(Texto), "[~w]", [S]).


% alinha o texto com espacos p manter as colunas organizadas
escrever_largura(Texto, Largura) :-
    atom_length(Texto, Tam),
    Falta is Largura - Tam,
    write(Texto),
    tab(Falta).


% pra executar no terminal (main.)
main :-
    puzzle(P),
    (   resolver(P, Grade)
    ->  writeln('Solucao encontrada:'),
        nl,
        imprimir_grade(P, Grade)
    ;   writeln('Nenhuma solucao foi encontrada.')
    ).