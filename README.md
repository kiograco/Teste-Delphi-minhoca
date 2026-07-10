# Minhoca no Buraco (Delphi VCL)

Simulação desktop em Delphi VCL: uma minhoca começa na posição `0` e sobe
até sair de um buraco, caindo um pouco após cada subida enquanto não
atinge a profundidade total. A interface mostra posição, progresso,
histórico de movimentos e uma cena desenhada da minhoca subindo.

## Estrutura do projeto

| Arquivo | Descrição |
|---|---|
| `TesteDelphi.dpr` / `.dproj` | Projeto principal |
| `uSimulacaoMinhoca.pas` | Lógica da simulação, **sem nenhuma dependência de VCL** |
| `uMinhocaForm.pas` / `.dfm` | Formulário (interface) |
| `Testes/TesteDelphiTests.dpr` | Projeto de testes automatizados (DUnitX) |
| `Testes/uSimulacaoMinhocaTests.pas` | Casos de teste da lógica da simulação |

## Como compilar e executar

1. Abra `TesteDelphi.dproj` no Delphi (Community Edition ou superior).
2. Pressione `F9` para compilar e rodar.

## Testes automatizados

A lógica da simulação foi isolada na classe `TSimulacaoMinhoca`
(`uSimulacaoMinhoca.pas`), que não usa nenhuma unit de VCL. Isso permite
testá-la diretamente, sem precisar abrir formulário nenhum, usando o
framework **DUnitX**.

### O que é testado

O arquivo `Testes/uSimulacaoMinhocaTests.pas` contém a fixture
`TSimulacaoMinhocaTests`, com os seguintes casos:

| Teste | O que verifica |
|---|---|
| `ParametrosValidos_ComValoresPadrao_DeveSerValido` | Profundidade 20, subida 5 e queda 3 (valores padrão) são aceitos |
| `ParametrosValidos_ProfundidadeZero_DeveSerInvalido` | Profundidade `<= 0` é rejeitada |
| `ParametrosValidos_SubidaZero_DeveSerInvalido` | Subida `<= 0` é rejeitada |
| `ParametrosValidos_QuedaNegativa_DeveSerInvalido` | Queda negativa é rejeitada |
| `ParametrosValidos_QuedaMaiorOuIgualASubida_DeveSerInvalido` | Queda `>=` subida é rejeitada (evitaria um loop infinito, já que a minhoca nunca sairia do buraco) |
| `Subir_IncrementaPosicaoEQtdSubidas` | Uma subida soma o valor de subida à posição e incrementa o contador |
| `Cair_NuncaFicaNegativa` | Uma queda maior que a posição atual trava o resultado em `0`, nunca negativo |
| `Subir_AoAtingirProfundidade_FinalizaSimulacao` | Ao alcançar a profundidade, `Ativa` vira `False` e `SaiuDoBuraco` vira `True` |
| `Cair_NaoOcorreAposSimulacaoFinalizada` | Chamar `Cair` depois que a simulação já terminou não tem efeito nenhum |
| `Ratio_RefleteProgressoEntreZeroEUm` | `Ratio` (usado na barra de progresso e nas cores do painel) reflete corretamente `posição / profundidade` |

### Como rodar os testes

O DUnitX já vem com versões recentes do Delphi (caso não apareça,
instale via `Tools > GetIt Package Manager > DUnitX`).

1. Abra `Testes/TesteDelphiTests.dpr` no Delphi.
2. Pressione `F9`. Um console será aberto executando os 10 testes e
   mostrando o resultado (passou/falhou) de cada um.
3. Também é gerado um relatório `TestResult.xml` no formato NUnit, que
   pode ser usado em pipelines de CI.

Como `TSimulacaoMinhoca` não depende de VCL, novos testes podem ser
adicionados sem precisar instanciar o formulário — basta criar a
instância da classe, chamar `Iniciar`/`Subir`/`Cair` e verificar o
estado com `Assert`.
