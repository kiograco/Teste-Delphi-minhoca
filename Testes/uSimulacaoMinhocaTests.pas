unit uSimulacaoMinhocaTests;

// Testes automatizados (DUnitX) da lógica pura da simulação. Como
// TSimulacaoMinhoca não depende de VCL, os testes rodam sem precisar
// instanciar nenhum formulário.

interface

uses
  DUnitX.TestFramework,
  uSimulacaoMinhoca;

type
  [TestFixture]
  TSimulacaoMinhocaTests = class
  public
    [Test]
    procedure ParametrosValidos_ComValoresPadrao_DeveSerValido;
    [Test]
    procedure ParametrosValidos_ProfundidadeZero_DeveSerInvalido;
    [Test]
    procedure ParametrosValidos_SubidaZero_DeveSerInvalido;
    [Test]
    procedure ParametrosValidos_QuedaNegativa_DeveSerInvalido;
    [Test]
    procedure ParametrosValidos_QuedaMaiorOuIgualASubida_DeveSerInvalido;

    [Test]
    procedure Subir_IncrementaPosicaoEQtdSubidas;
    [Test]
    procedure Cair_NuncaFicaNegativa;
    [Test]
    procedure Subir_AoAtingirProfundidade_FinalizaSimulacao;
    [Test]
    procedure Cair_NaoOcorreAposSimulacaoFinalizada;
    [Test]
    procedure Ratio_RefleteProgressoEntreZeroEUm;
  end;

implementation

procedure TSimulacaoMinhocaTests.ParametrosValidos_ComValoresPadrao_DeveSerValido;
var
  Msg: string;
begin
  Assert.IsTrue(TSimulacaoMinhoca.ParametrosValidos(20, 5, 3, Msg));
  Assert.AreEqual('', Msg);
end;

procedure TSimulacaoMinhocaTests.ParametrosValidos_ProfundidadeZero_DeveSerInvalido;
var
  Msg: string;
begin
  Assert.IsFalse(TSimulacaoMinhoca.ParametrosValidos(0, 5, 3, Msg));
  Assert.IsTrue(Msg <> '');
end;

procedure TSimulacaoMinhocaTests.ParametrosValidos_SubidaZero_DeveSerInvalido;
var
  Msg: string;
begin
  Assert.IsFalse(TSimulacaoMinhoca.ParametrosValidos(20, 0, 3, Msg));
  Assert.IsTrue(Msg <> '');
end;

procedure TSimulacaoMinhocaTests.ParametrosValidos_QuedaNegativa_DeveSerInvalido;
var
  Msg: string;
begin
  Assert.IsFalse(TSimulacaoMinhoca.ParametrosValidos(20, 5, -1, Msg));
  Assert.IsTrue(Msg <> '');
end;

procedure TSimulacaoMinhocaTests.ParametrosValidos_QuedaMaiorOuIgualASubida_DeveSerInvalido;
var
  Msg: string;
begin
  // Queda igual à subida ou maior nunca deixaria a minhoca sair do buraco
  Assert.IsFalse(TSimulacaoMinhoca.ParametrosValidos(20, 5, 5, Msg));
  Assert.IsFalse(TSimulacaoMinhoca.ParametrosValidos(20, 5, 6, Msg));
end;

procedure TSimulacaoMinhocaTests.Subir_IncrementaPosicaoEQtdSubidas;
var
  Sim: TSimulacaoMinhoca;
begin
  Sim := TSimulacaoMinhoca.Create;
  try
    Sim.Iniciar(20, 5, 3);
    Sim.Subir;
    Assert.AreEqual(5, Sim.PosicaoAtual);
    Assert.AreEqual(1, Sim.QtdSubidas);
  finally
    Sim.Free;
  end;
end;

procedure TSimulacaoMinhocaTests.Cair_NuncaFicaNegativa;
var
  Sim: TSimulacaoMinhoca;
begin
  Sim := TSimulacaoMinhoca.Create;
  try
    Sim.Iniciar(20, 5, 10); // queda maior que a posição alcançada após 1 subida
    Sim.Subir;              // posição = 5
    Sim.Cair;                // 5 - 10 deveria travar em 0, nunca negativo
    Assert.AreEqual(0, Sim.PosicaoAtual);
  finally
    Sim.Free;
  end;
end;

procedure TSimulacaoMinhocaTests.Subir_AoAtingirProfundidade_FinalizaSimulacao;
var
  Sim: TSimulacaoMinhoca;
begin
  Sim := TSimulacaoMinhoca.Create;
  try
    Sim.Iniciar(10, 5, 3);
    Sim.Subir; // posição = 5
    Assert.IsTrue(Sim.Ativa);
    Sim.Subir; // posição = 10 -> saiu do buraco
    Assert.IsFalse(Sim.Ativa);
    Assert.IsTrue(Sim.SaiuDoBuraco);
  finally
    Sim.Free;
  end;
end;

procedure TSimulacaoMinhocaTests.Cair_NaoOcorreAposSimulacaoFinalizada;
var
  Sim: TSimulacaoMinhoca;
  PosicaoFinal: Integer;
begin
  Sim := TSimulacaoMinhoca.Create;
  try
    Sim.Iniciar(10, 5, 3);
    Sim.Subir; // 5
    Sim.Subir; // 10, finaliza
    PosicaoFinal := Sim.PosicaoAtual;
    Sim.Cair;  // não deve ter efeito: simulação já não está ativa
    Assert.AreEqual(PosicaoFinal, Sim.PosicaoAtual);
  finally
    Sim.Free;
  end;
end;

procedure TSimulacaoMinhocaTests.Ratio_RefleteProgressoEntreZeroEUm;
var
  Sim: TSimulacaoMinhoca;
begin
  Sim := TSimulacaoMinhoca.Create;
  try
    Sim.Iniciar(20, 5, 3);
    Assert.AreEqual(0.0, Sim.Ratio, 0.0001);
    Sim.Subir; // 5 / 20 = 0.25
    Assert.AreEqual(0.25, Sim.Ratio, 0.0001);
  finally
    Sim.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TSimulacaoMinhocaTests);

end.
