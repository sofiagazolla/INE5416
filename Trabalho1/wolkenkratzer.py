from itertools import permutations


# conta quantos predios da para ver olhando da esquerda para a direita
def visiveis(linha):
    maior = 0
    quantidade = 0

    for altura in linha:
        if altura > maior:
            maior = altura
            quantidade += 1

    return quantidade


# confere se a linha bate com a pista informada, considerando que zero significa que nao tem pista
def satisfaz_pista(pista, linha):
    if pista == 0:
        return True

    return visiveis(linha) == pista


# confere se a linha respeita as pistas dos dois lados
def linha_valida(pista_inicio, pista_fim, linha):
    return satisfaz_pista(pista_inicio, linha) and satisfaz_pista(pista_fim, linha[::-1])


# testa todas as ordens possiveis dos numeros de 1 ate n e guarda as que respeitam as pistas
def permutacoes_validas(n, pista_inicio, pista_fim):
    resultado = []

    for permutacao in permutations(range(1, n + 1)):
        linha = list(permutacao)

        if linha_valida(pista_inicio, pista_fim, linha):
            resultado.append(linha)

    return resultado


# monta a lista de possibilidades para cada linha ou coluna com base nas pistas
def gerar_opcoes(n, pistas_inicio, pistas_fim):
    opcoes = []

    for pista_inicio, pista_fim in zip(pistas_inicio, pistas_fim):
        opcoes.append(permutacoes_validas(n, pista_inicio, pista_fim))

    return opcoes


# troca as linhas pelas colunas da matriz
def transpor(tabuleiro):
    return [list(coluna) for coluna in zip(*tabuleiro)]


# confere se as colunas ainda podem ser completadas sem desrespeitar as pistas
def colunas_ainda_possiveis(tabuleiro, opcoes_colunas):
    colunas_parciais = transpor(tabuleiro)

    for prefixo, opcoes in zip(colunas_parciais, opcoes_colunas):
        coluna_possivel = False

        for opcao in opcoes:
            # confere se os numeros da coluna parcial combinam com o inicio de alguma opcao valida
            if opcao[:len(prefixo)] == prefixo:
                coluna_possivel = True
                break

        if not coluna_possivel:
            return False

    return True


# resolve o puzzle testando possibilidades ate encontrar uma solucao
def resolver(n, topo, baixo, esquerda, direita):

    # confere se todas as pistas foram informadas e se seus valores fazem sentido
    if not (len(topo) == n and len(baixo) == n and len(esquerda) == n and len(direita) == n):
        return None

    todas_pistas = topo + baixo + esquerda + direita

    for pista in todas_pistas:
        if pista < 0 or pista > n:
            return None

    # gera as possibilidades de cada linha considerando as pistas da esquerda e da direita
    opcoes_linhas = gerar_opcoes(n, esquerda, direita)

    # gera as possibilidades de cada coluna considerando as pistas de cima e de baixo
    opcoes_colunas = gerar_opcoes(n, topo, baixo)

    # tenta montar o tabuleiro linha por linha usando backtracking
    def buscar(tabuleiro, indice_linha):

        # termina quando todas as linhas ja foram preenchidas
        if indice_linha == n:
            return tabuleiro

        # testa cada possibilidade para a linha atual
        for linha in opcoes_linhas[indice_linha]:
            novo_tabuleiro = tabuleiro + [linha]

            # so continua se as colunas ainda tiverem alguma possibilidade valida
            if colunas_ainda_possiveis(novo_tabuleiro, opcoes_colunas):
                solucao = buscar(novo_tabuleiro, indice_linha + 1)

                if solucao is not None:
                    return solucao

        # retorna nada se nenhuma possibilidade funcionar
        return None

    return buscar([], 0)


# transforma a pista em texto e mostra um ponto quando ela vale zero
def mostrar_pista(pista):
    if pista == 0:
        return "."

    return str(pista)


# mostra o tabuleiro com todas as pistas ao redor
def imprimir_puzzle(topo, baixo, esquerda, direita, tabuleiro):
    print("    " + " ".join(map(mostrar_pista, topo)))

    # calcula o tamanho da borda de acordo com o tamanho do tabuleiro
    largura = 2 * len(topo) + 1

    print("   +" + "-" * largura + "+")

    for pista_esquerda, linha, pista_direita in zip(esquerda, tabuleiro, direita):
        print(mostrar_pista(pista_esquerda) + " | " + " ".join(map(str, linha)) + " | " + mostrar_pista(pista_direita))

    print("   +" + "-" * largura + "+")
    print("    " + " ".join(map(mostrar_pista, baixo)))


# exemplo de puzzle para testar o resolvedor
n = 6

topo = [4, 1, 2, 2, 3, 2]
baixo = [1, 3, 5, 2, 4, 2]
esquerda = [2, 3, 3, 4, 2, 1]
direita = [2, 4, 2, 3, 1, 4]


def main():
    print("Wolkenkratzer - resolvedor em Python")
    print()

    solucao = resolver(n, topo, baixo, esquerda, direita)

    if solucao is None:
        print("Nenhuma solução foi encontrada.")

    else:
        print("Solução encontrada:")
        print()
        imprimir_puzzle(topo, baixo, esquerda, direita, solucao)


if __name__ == "__main__":
    main()
