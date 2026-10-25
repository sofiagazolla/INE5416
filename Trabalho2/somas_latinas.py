# somas latinas (lateinische summen) - solver em python

# entrada do puzzle:
# "x"    -> celula branca (recebera um numero de 1 ate n)
# numero -> celula preta com pista de soma
# "p"    -> celula preta sem pista
puzzle = [
    ["x", "x", "x", "x", "x", 5, 1, 1],
    ["x", "x", "x", "x", 21, 17, 10, "x"],
    [12, "x", 24, "x", "x", "x", "x", 7],
    ["x", 13, "x", "x", 21, "x", 17, "x"],
    [11, "x", "x", "x", "x", 16, "x", 13],
    ["x", 18, 11, 13, "x", "x", "x", "x"],
    ["x", 15, "x", 8, 12, "x", "x", "x"],
    [5, "x", 6, 7, "x", "x", "x", "x"],
]

# os 8 deslocamentos (linha, coluna) para chegar nos vizinhos
DESLOCAMENTOS = [
    (-1, -1), (-1, 0), (-1, 1),
    (0, -1),           (0, 1),
    (1, -1),  (1, 0),  (1, 1)
]


# conta quantas celulas brancas tem em uma linha (esse eh o n das regras)
def contar_brancas(linha):
    quantidade = 0
    for celula in linha:
        if celula == "x":
            quantidade += 1
    return quantidade


# devolve as posicoes (i, j) dos 8 vizinhos que estao dentro do tabuleiro
def vizinhos(t, i, j):
    resultado = []
    for di, dj in DESLOCAMENTOS:
        i2 = i + di
        j2 = j + dj
        if 0 <= i2 < t and 0 <= j2 < t:
            resultado.append((i2, j2))
    return resultado


# regra 2: confere se o valor v ja aparece na linha i ou na coluna j
def repetido(grade, t, i, j, v):
    for k in range(t):
        if grade[i][k] == v or grade[k][j] == v:
            return True
    return False


# regra 3: confere se as pistas das pretas vizinhas de (i, j) ainda podem dar certo
def somas_possiveis(puzzle, grade, t, n, i, j):
    for i2, j2 in vizinhos(t, i, j):
        pista = puzzle[i2][j2]

        # so as pretas com pista (numero) interessam
        if not isinstance(pista, int):
            continue

        soma_atual = 0
        faltam = 0

        # soma o que ja foi preenchido e conta quantas brancas ainda estao vazias
        for i3, j3 in vizinhos(t, i2, j2):
            if puzzle[i3][j3] == "x":
                if grade[i3][j3] == 0:
                    faltam += 1
                else:
                    soma_atual += grade[i3][j3]

        # passou da pista, entao nao tem como dar certo
        if soma_atual > pista:
            return False

        # ja preencheu todos os vizinhos, a soma tem que bater exatamente
        if faltam == 0 and soma_atual != pista:
            return False

        # mesmo colocando o maior valor possivel nas que faltam, nao chega na pista
        if soma_atual + faltam * n < pista:
            return False

    return True


# resolve o puzzle: preenche as brancas uma por uma e volta quando da errado
def resolver(puzzle):
    t = len(puzzle)
    n = contar_brancas(puzzle[0])

    # grade de valores: 0 significa preta ou branca ainda sem valor
    grade = []
    for i in range(t):
        grade.append([0] * t)

    # lista das posicoes brancas, na ordem em que vao ser preenchidas
    brancas = []
    for i in range(t):
        for j in range(t):
            if puzzle[i][j] == "x":
                brancas.append((i, j))

    def buscar(k):
        # termina quando todas as brancas ja foram preenchidas
        if k == len(brancas):
            return True

        i, j = brancas[k]

        # testa cada valor possivel para a celula atual
        for v in range(1, n + 1):
            if repetido(grade, t, i, j, v):
                continue

            grade[i][j] = v

            # so continua se as somas ainda puderem dar certo
            if somas_possiveis(puzzle, grade, t, n, i, j):
                if buscar(k + 1):
                    return True

            # nao deu certo, desfaz e tenta o proximo valor
            grade[i][j] = 0

        # nenhum valor funcionou, volta para a celula anterior
        return False

    if buscar(0):
        return grade

    return None


# decide o texto de cada celula
def texto_celula(celula, valor):
    if celula == "x":
        return str(valor)

    if celula == "p":
        return "[ ]"

    return "[" + str(celula) + "]"


# imprime o tabuleiro: preta aparece como [soma], branca como o numero
def imprimir_grade(puzzle, grade):
    for linha_p, linha_v in zip(puzzle, grade):
        linha = ""

        for celula, valor in zip(linha_p, linha_v):
            linha += texto_celula(celula, valor).ljust(6)

        print(linha)


def main():
    solucao = resolver(puzzle)

    if solucao is None:
        print("nenhuma solucao foi encontrada.")

    else:
        print("solucao encontrada:")
        print()
        imprimir_grade(puzzle, solucao)


if __name__ == "__main__":
    main()