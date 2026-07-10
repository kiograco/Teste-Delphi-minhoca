unit uSimulacaoMinhoca;

// Lógica pura da simulação, sem nenhuma dependência de VCL.
// Isso permite reutilizar a classe em outra interface (ex.: FireMonkey)
// e testá-la com DUnitX sem precisar instanciar formulários.

interface

uses
  System.SysUtils, System.Generics.Collections;

type
  TNotificacaoSimulacao = procedure(Sender: TObject) of object;

  TSimulacaoMinhoca = class
  private
    FPosicaoAtual: Integer;
    FQtdSubidas: Integer;
    FProfundidadeBuraco: Integer;
    FValorSubida: Integer;
    FValorQueda: Integer;
    FVariacaoPercentual: Integer;
    FAtiva: Boolean;
    FHistoricoPosicoes: TList<Integer>;
    FOnSubiu: TNotificacaoSimulacao;
    FOnCaiu: TNotificacaoSimulacao;
    FOnFinalizou: TNotificacaoSimulacao;
    function GetSaiuDoBuraco: Boolean;
    function GetRatio: Double;
    function ValorComVariacao(ABase: Integer): Integer;
  public
    constructor Create;
    destructor Destroy; override;

    // Valida os parâmetros antes de iniciar. Retorna False e preenche
    // AMensagemErro quando algum valor é inválido (inclusive o caso em que
    // a queda é maior ou igual à subida, o que impediria a minhoca de sair).
    class function ParametrosValidos(AProfundidade, ASubida, AQueda: Integer;
      out AMensagemErro: string): Boolean;

    procedure Iniciar(AProfundidade, ASubida, AQueda: Integer);
    procedure Subir;
    procedure Cair;
    procedure Resetar;

    property PosicaoAtual: Integer read FPosicaoAtual;
    property QtdSubidas: Integer read FQtdSubidas;
    property ProfundidadeBuraco: Integer read FProfundidadeBuraco;
    property ValorSubida: Integer read FValorSubida;
    property ValorQueda: Integer read FValorQueda;
    property VariacaoPercentual: Integer read FVariacaoPercentual write FVariacaoPercentual;
    property Ativa: Boolean read FAtiva;
    property SaiuDoBuraco: Boolean read GetSaiuDoBuraco;
    property Ratio: Double read GetRatio;
    property HistoricoPosicoes: TList<Integer> read FHistoricoPosicoes;

    property OnSubiu: TNotificacaoSimulacao read FOnSubiu write FOnSubiu;
    property OnCaiu: TNotificacaoSimulacao read FOnCaiu write FOnCaiu;
    property OnFinalizou: TNotificacaoSimulacao read FOnFinalizou write FOnFinalizou;
  end;

implementation

{ TSimulacaoMinhoca }

constructor TSimulacaoMinhoca.Create;
begin
  inherited Create;
  FHistoricoPosicoes := TList<Integer>.Create;
  Randomize;
end;

destructor TSimulacaoMinhoca.Destroy;
begin
  FHistoricoPosicoes.Free;
  inherited Destroy;
end;

class function TSimulacaoMinhoca.ParametrosValidos(AProfundidade, ASubida, AQueda: Integer;
  out AMensagemErro: string): Boolean;
begin
  Result := False;
  AMensagemErro := '';

  if AProfundidade <= 0 then
  begin
    AMensagemErro := 'A profundidade deve ser um n' + #250 + 'mero inteiro maior que zero.';
    Exit;
  end;

  if ASubida <= 0 then
  begin
    AMensagemErro := 'A subida deve ser um n' + #250 + 'mero inteiro maior que zero.';
    Exit;
  end;

  if AQueda < 0 then
  begin
    AMensagemErro := 'A queda n' + #227 + 'o pode ser negativa.';
    Exit;
  end;

  if AQueda >= ASubida then
  begin
    AMensagemErro := 'A queda deve ser menor que a subida, sen' + #227 + 'o a minhoca nunca sai do buraco.';
    Exit;
  end;

  Result := True;
end;

procedure TSimulacaoMinhoca.Iniciar(AProfundidade, ASubida, AQueda: Integer);
begin
  FProfundidadeBuraco := AProfundidade;
  FValorSubida := ASubida;
  FValorQueda := AQueda;
  FPosicaoAtual := 0;
  FQtdSubidas := 0;
  FAtiva := True;

  FHistoricoPosicoes.Clear;
  FHistoricoPosicoes.Add(FPosicaoAtual);
end;

// Aplica uma variação aleatória de +/- FVariacaoPercentual% sobre um valor
// base (usada opcionalmente para tornar subidas/quedas menos previsíveis).
function TSimulacaoMinhoca.ValorComVariacao(ABase: Integer): Integer;
var
  Delta: Integer;
begin
  Result := ABase;

  if (FVariacaoPercentual <= 0) or (ABase <= 0) then
    Exit;

  Delta := Round(ABase * FVariacaoPercentual / 100);
  if Delta < 1 then
    Exit;

  Result := ABase + Random(2 * Delta + 1) - Delta;
  if Result < 0 then
    Result := 0;
end;

procedure TSimulacaoMinhoca.Subir;
begin
  if not FAtiva then
    Exit;

  Inc(FPosicaoAtual, ValorComVariacao(FValorSubida));
  Inc(FQtdSubidas);
  FHistoricoPosicoes.Add(FPosicaoAtual);

  if Assigned(FOnSubiu) then
    FOnSubiu(Self);

  if FPosicaoAtual >= FProfundidadeBuraco then
  begin
    FAtiva := False;
    if Assigned(FOnFinalizou) then
      FOnFinalizou(Self);
  end;
end;

// Só deve ser chamada quando SaiuDoBuraco = False (garantido pelo chamador).
procedure TSimulacaoMinhoca.Cair;
begin
  if not FAtiva then
    Exit;

  FPosicaoAtual := FPosicaoAtual - ValorComVariacao(FValorQueda);
  if FPosicaoAtual < 0 then
    FPosicaoAtual := 0;

  FHistoricoPosicoes.Add(FPosicaoAtual);

  if Assigned(FOnCaiu) then
    FOnCaiu(Self);
end;

// Interrompe e zera o estado, usada pelo botão Limpar/Reiniciar da interface.
procedure TSimulacaoMinhoca.Resetar;
begin
  FAtiva := False;
  FPosicaoAtual := 0;
  FQtdSubidas := 0;
  FProfundidadeBuraco := 0;
  FValorSubida := 0;
  FValorQueda := 0;
  FHistoricoPosicoes.Clear;
end;

function TSimulacaoMinhoca.GetSaiuDoBuraco: Boolean;
begin
  // A checagem de profundidade > 0 evita falso positivo logo após Resetar
  // (onde posição e profundidade ficam ambas em 0)
  Result := (FProfundidadeBuraco > 0) and (FPosicaoAtual >= FProfundidadeBuraco);
end;

function TSimulacaoMinhoca.GetRatio: Double;
begin
  if FProfundidadeBuraco > 0 then
    Result := FPosicaoAtual / FProfundidadeBuraco
  else
    Result := 0;

  if Result > 1 then
    Result := 1
  else if Result < 0 then
    Result := 0;
end;

end.
