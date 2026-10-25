module Main where

import Data.List (isPrefixOf, nub, permutations, transpose)

type Tabuleiro = [[Int]]
type Pistas = [Int]


-- conta qtos predios sao visiveis olhando da esquerda p direita
-- usa um acumulador 'maior' que vai comparando e atualizando e um contador 'quantidade'
visiveis :: [Int] -> Int
visiveis = snd . foldl passo (0, 0)
  where
    passo (maior, quantidade) altura
      | altura > maior = (altura, quantidade + 1)
      | otherwise = (maior, quantidade)


-- verifica se a linha satisfaz a condicao da pista, chamando visiveis
satisfazPista :: Int -> [Int] -> Bool
satisfazPista 0 _ = True -- nao tem valor, entao aceita qualquer linha
satisfazPista pista xs = visiveis xs == pista


-- verifica as duas pistas de uma linha
-- usa reverse para verificar a pista do outro lado
linhaValida :: Int -> Int -> [Int] -> Bool
linhaValida pistaInicio pistaFim xs =
  satisfazPista pistaInicio xs
    && satisfazPista pistaFim (reverse xs)


-- monta os valores de uma linha: (n - maxAltura) zeros (celulas vazias, X)
-- seguidos de 1..maxAltura. Ex: n=6, maxAltura=4 -> [0,0,1,2,3,4]
valoresLinha :: Int -> Int -> [Int]
valoresLinha n maxAltura =
  replicate quantidadeVazios 0 ++ [1 .. maxAltura]
  where
    quantidadeVazios =
      n - maxAltura


-- gera todas as linhas possiveis e mantem somente as que satisfazem as duas pistas
permutacoesValidas :: Int -> Int -> Int -> Int -> [[Int]]
permutacoesValidas n maxAltura pistaInicio pistaFim =
  filter
    (linhaValida pistaInicio pistaFim)
    (nub (permutations (valoresLinha n maxAltura))) -- nub remove permutacoes repetidas, que aparecem quando ha varios 0s


-- gera as opcoes validas para cada linha ou coluna
-- zipWith junta cada pista do inicio com a pista correspondente do fim
gerarOpcoes :: Int -> Int -> Pistas -> Pistas -> [[[Int]]]
gerarOpcoes n maxAltura pistasInicio pistasFim =
  zipWith
    (permutacoesValidas n maxAltura)
    pistasInicio
    pistasFim


-- verifica se as colunas que ja foram parcialmente montadas ainda podem dar certo
colunasAindaPossiveis :: Tabuleiro -> [[[Int]]] -> Bool
colunasAindaPossiveis tabuleiro opcoesColunas =
  and $
    zipWith
      colunaPossivel
      (transpose tabuleiro) -- transforma as linhas atuais em colunas
      opcoesColunas
  where
    colunaPossivel prefixo opcoes =
      any (prefixo `isPrefixOf`) opcoes
      -- verifica se a coluna parcial eh o inicio de pelo menos uma opcao valida


-- resolve o puzzle usando backtracking
-- vai montando o tabuleiro linha por linha e volta quando alguma escolha nao funciona
resolver :: Int -> Int -> Pistas -> Pistas -> Pistas -> Pistas -> Maybe Tabuleiro
resolver n maxAltura topo baixo esquerda direita
  | not entradaValida = Nothing
  | otherwise = buscar [] opcoesLinhas
  where

    -- possibilidades de cada linha, considerando esquerda e direita
    opcoesLinhas =
      gerarOpcoes n maxAltura esquerda direita

    -- possibilidades de cada coluna, considerando topo e baixo
    opcoesColunas =
      gerarOpcoes n maxAltura topo baixo


    -- confere se os valores recebidos fazem sentido antes de tentar resolver
    entradaValida =
      maxAltura >= 1
        && maxAltura <= n
        && all
          ((== n) . length)
          [topo, baixo, esquerda, direita]
        && all
          pistaValida
          (topo ++ baixo ++ esquerda ++ direita)

    -- pista 0 eh permitida pq representa uma pista ausente
    pistaValida pista =
      pista >= 0 && pista <= maxAltura


    -- funcao que vai montando o tabuleiro recursivamente
    buscar :: Tabuleiro -> [[[Int]]] -> Maybe Tabuleiro

    -- se nao tem mais linhas p colocar, terminou e encontrou uma solucao
    buscar tabuleiro [] =
      Just tabuleiro

    -- pega as opcoes da linha atual e deixa as proximas separadas em 'restantes'
    buscar tabuleiro (opcoesAtuais : restantes) =
      tentar opcoesAtuais
      where

        -- se testou todas as opcoes dessa linha e nenhuma funcionou, volta
        tentar [] =
          Nothing

        -- pega uma linha possivel e deixa as outras guardadas p caso essa nao funcione
        tentar (linha : outrasLinhas)

          -- so continua se as colunas ainda puderem formar uma solucao valida
          | colunasAindaPossiveis novoTabuleiro opcoesColunas =
              case buscar novoTabuleiro restantes of

                -- conseguiu completar o resto do tabuleiro
                Just solucao ->
                  Just solucao

                -- essa linha acabou levando a um caminho sem solucao
                -- entao volta e tenta a proxima
                Nothing ->
                  tentar outrasLinhas

          -- se a coluna ja ficou impossivel, nem continua com essa linha
          | otherwise =
              tentar outrasLinhas

          where
            -- adiciona a linha escolhida no tabuleiro atual
            novoTabuleiro =
              tabuleiro ++ [linha]


-- transforma as pistas em texto p imprimir
-- 0 aparece como "." pq significa que nao tem pista
mostrarPista :: Int -> String
mostrarPista 0 = "."
mostrarPista x = show x


-- transforma os valores do tabuleiro em texto
-- 0 aparece como X pq representa uma celula vazia
mostrarCelula :: Int -> String
mostrarCelula 0 = "X"
mostrarCelula x = show x


-- imprime o tabuleiro junto com as pistas
imprimirPuzzle :: Pistas -> Pistas -> Pistas -> Pistas -> Tabuleiro -> IO ()
imprimirPuzzle topo baixo esquerda direita tabuleiro = do
  putStrLn $
    "    " ++ unwords (map mostrarPista topo)

  putStrLn "  +-------------+"

  -- junta a pista da esquerda, a linha e a pista da direita
  mapM_
    imprimirLinha
    (zip3 esquerda tabuleiro direita)

  putStrLn "  +-------------+"

  putStrLn $
    "    " ++ unwords (map mostrarPista baixo)

  where
    imprimirLinha (pistaEsquerda, linha, pistaDireita) =
      putStrLn $
        mostrarPista pistaEsquerda
          ++ " | "
          ++ unwords (map mostrarCelula linha)
          ++ " | "
          ++ mostrarPista pistaDireita


-- tamanho do tabuleiro
n :: Int
n = 6


-- maior altura que pode aparecer
maxAltura :: Int
maxAltura = 5


-- pistas que nao existem sao representadas por 0
topo :: Pistas
topo = [2, 3, 1, 4, 2, 3]

baixo :: Pistas
baixo = [2, 2, 2, 1, 4, 2]

esquerda :: Pistas
esquerda = [2, 3, 2, 1, 4, 3]

direita :: Pistas
direita = [2, 2, 2, 4, 1, 2]


-- chama o resolver e mostra o resultado
main :: IO ()
main = do
  case resolver n maxAltura topo baixo esquerda direita of

    Nothing ->
      putStrLn "Nenhuma solucao foi encontrada."

    Just solucao -> do
      putStrLn "Solucao encontrada:"
      putStrLn ""
      imprimirPuzzle topo baixo esquerda direita solucao