unit uMinhocaForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.IniFiles, System.Generics.Collections, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls,
  uSimulacaoMinhoca;

type
  TfrmMinhoca = class(TForm)
    lblProfundidadeCaption: TLabel;
    edtProfundidade: TEdit;
    lblSubidaCaption: TLabel;
    edtSubida: TEdit;
    lblQuedaCaption: TLabel;
    edtQueda: TEdit;
    chkAleatorio: TCheckBox;
    lblVelocidadeCaption: TLabel;
    trkVelocidade: TTrackBar;
    lblVelocidadeValor: TLabel;
    btnIniciar: TButton;
    btnPausar: TButton;
    btnLimpar: TButton;
    lblPosicaoCaption: TLabel;
    lblPosicaoAtual: TLabel;
    lblSubidasCaption: TLabel;
    lblQtdSubidas: TLabel;
    prgProgresso: TProgressBar;
    lblRecorde: TLabel;
    btnExportar: TButton;
    lstHistorico: TListBox;
    pnlStatus: TPanel;
    imgBuraco: TImage;
    lblGraficoCaption: TLabel;
    imgGrafico: TImage;
    tmrQueda: TTimer;
    tmrAnimacao: TTimer;
    dlgSalvarHistorico: TSaveDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnIniciarClick(Sender: TObject);
    procedure btnPausarClick(Sender: TObject);
    procedure btnLimparClick(Sender: TObject);
    procedure btnExportarClick(Sender: TObject);
    procedure tmrQuedaTimer(Sender: TObject);
    procedure tmrAnimacaoTimer(Sender: TObject);
    procedure trkVelocidadeChange(Sender: TObject);
    procedure chkAleatorioClick(Sender: TObject);
  private
    { Simulação (lógica) e estado de exibição }
    FSimulacao: TSimulacaoMinhoca;
    FDisplayPosicao: Double;
    FPausado: Boolean;
    FTimerEstavaAtivoAntesDaPausa: Boolean;
    FMelhorQtdSubidas: Integer;

    function ValidarEntradas(out AProfundidade, ASubida, AQueda: Integer): Boolean;
    procedure DefinirValoresPadrao;
    procedure AtualizarInterface;
    procedure AtualizarCorPainel;
    procedure DesenharCena(APosicaoExibida: Double);
    procedure DesenharGrafico;
    procedure RegistrarHistorico(const AMensagem: string);
    procedure HabilitarControlesDeEntrada(AHabilitar: Boolean);

    { Handlers dos eventos disparados pela TSimulacaoMinhoca }
    procedure SimulacaoSubiu(Sender: TObject);
    procedure SimulacaoCaiu(Sender: TObject);
    procedure SimulacaoFinalizou(Sender: TObject);

    { Persistência de parâmetros e recorde em arquivo .ini }
    function NomeArquivoConfig: string;
    procedure CarregarConfiguracao;
    procedure SalvarConfiguracao;
    procedure AtualizarLabelRecorde;
    procedure RegistrarRecordeSeNecessario;
  public
  end;

var
  frmMinhoca: TfrmMinhoca;

implementation

{$R *.dfm}

const
  EMOJI_COMEMORACAO = #55356 + #57225; // 🎉
  EMOJI_TROFEU = #55356 + #57286;      // 🏆

{ TfrmMinhoca }

procedure TfrmMinhoca.FormCreate(Sender: TObject);
begin
  // Cada TImage desenha em um bitmap do próprio tamanho do componente
  imgBuraco.Picture.Bitmap.SetSize(imgBuraco.Width, imgBuraco.Height);
  imgGrafico.Picture.Bitmap.SetSize(imgGrafico.Width, imgGrafico.Height);

  FSimulacao := TSimulacaoMinhoca.Create;
  FSimulacao.OnSubiu := SimulacaoSubiu;
  FSimulacao.OnCaiu := SimulacaoCaiu;
  FSimulacao.OnFinalizou := SimulacaoFinalizou;

  FPausado := False;
  FDisplayPosicao := 0;
  FMelhorQtdSubidas := -1;

  CarregarConfiguracao;
  tmrQueda.Interval := trkVelocidade.Position;
  lblVelocidadeValor.Caption := Format('%d ms', [trkVelocidade.Position]);

  btnPausar.Enabled := False;

  AtualizarInterface;
  DesenharCena(0);
end;

procedure TfrmMinhoca.FormDestroy(Sender: TObject);
begin
  SalvarConfiguracao;
  FSimulacao.Free;
end;

procedure TfrmMinhoca.DefinirValoresPadrao;
begin
  edtProfundidade.Text := '20';
  edtSubida.Text := '5';
  edtQueda.Text := '3';
end;

// Valida os três campos numéricos e, em seguida, as regras de negócio da
// simulação (via TSimulacaoMinhoca.ParametrosValidos - inclui o caso da
// queda ser maior ou igual à subida, que geraria um loop infinito).
function TfrmMinhoca.ValidarEntradas(out AProfundidade, ASubida, AQueda: Integer): Boolean;
var
  MensagemErro: string;
begin
  Result := False;

  if not TryStrToInt(Trim(edtProfundidade.Text), AProfundidade) or (AProfundidade <= 0) then
  begin
    ShowMessage('Informe um n' + #250 + 'mero inteiro positivo para a profundidade do buraco.');
    edtProfundidade.SetFocus;
    Exit;
  end;

  if not TryStrToInt(Trim(edtSubida.Text), ASubida) or (ASubida <= 0) then
  begin
    ShowMessage('Informe um n' + #250 + 'mero inteiro positivo para a subida.');
    edtSubida.SetFocus;
    Exit;
  end;

  if not TryStrToInt(Trim(edtQueda.Text), AQueda) or (AQueda < 0) then
  begin
    ShowMessage('Informe um n' + #250 + 'mero inteiro maior ou igual a zero para a queda.');
    edtQueda.SetFocus;
    Exit;
  end;

  if not TSimulacaoMinhoca.ParametrosValidos(AProfundidade, ASubida, AQueda, MensagemErro) then
  begin
    ShowMessage(MensagemErro);
    edtQueda.SetFocus;
    Exit;
  end;

  Result := True;
end;

procedure TfrmMinhoca.btnIniciarClick(Sender: TObject);
var
  Profundidade, Subida, Queda: Integer;
begin
  // Impede reiniciar a simulação enquanto ela já está em andamento
  if FSimulacao.Ativa then
    Exit;

  if not ValidarEntradas(Profundidade, Subida, Queda) then
    Exit;

  SalvarConfiguracao;

  FSimulacao.Iniciar(Profundidade, Subida, Queda);
  FDisplayPosicao := 0;
  FPausado := False;

  lstHistorico.Clear;
  RegistrarHistorico(Format('Simula' + #231 + #227 + 'o iniciada. Profundidade: %d cm | Subida: %d cm | Queda: %d cm',
    [Profundidade, Subida, Queda]));

  btnIniciar.Enabled := False;
  btnPausar.Enabled := True;
  btnPausar.Caption := 'Pausar';
  HabilitarControlesDeEntrada(False);

  tmrAnimacao.Enabled := True;
  AtualizarInterface;

  FSimulacao.Subir;
end;

procedure TfrmMinhoca.btnPausarClick(Sender: TObject);
begin
  if not FSimulacao.Ativa then
    Exit;

  FPausado := not FPausado;
  if FPausado then
  begin
    // Congela apenas a espera entre a queda e a próxima subida
    FTimerEstavaAtivoAntesDaPausa := tmrQueda.Enabled;
    tmrQueda.Enabled := False;
    btnPausar.Caption := 'Retomar';
    RegistrarHistorico('Simula' + #231 + #227 + 'o pausada.');
  end
  else
  begin
    if FTimerEstavaAtivoAntesDaPausa then
      tmrQueda.Enabled := True;
    btnPausar.Caption := 'Pausar';
    RegistrarHistorico('Simula' + #231 + #227 + 'o retomada.');
  end;
end;

// Dispara uma subida; a queda seguinte (se houver) acontece de forma
// encadeada dentro do próprio evento OnSubiu (ver SimulacaoSubiu).
procedure TfrmMinhoca.tmrQuedaTimer(Sender: TObject);
begin
  tmrQueda.Enabled := False;
  FSimulacao.Subir;
end;

// Anima suavemente a posição exibida da minhoca em direção à posição real
// da simulação, sem alterar a lógica (que continua avançando em saltos
// discretos por subida/queda, apenas o desenho é interpolado).
procedure TfrmMinhoca.tmrAnimacaoTimer(Sender: TObject);
var
  Alvo: Double;
begin
  Alvo := FSimulacao.PosicaoAtual;

  if Abs(FDisplayPosicao - Alvo) < 0.4 then
    FDisplayPosicao := Alvo
  else
    FDisplayPosicao := FDisplayPosicao + (Alvo - FDisplayPosicao) * 0.35;

  DesenharCena(FDisplayPosicao);
end;

procedure TfrmMinhoca.trkVelocidadeChange(Sender: TObject);
begin
  tmrQueda.Interval := trkVelocidade.Position;
  lblVelocidadeValor.Caption := Format('%d ms', [trkVelocidade.Position]);
end;

procedure TfrmMinhoca.chkAleatorioClick(Sender: TObject);
begin
  if chkAleatorio.Checked then
    FSimulacao.VariacaoPercentual := 20
  else
    FSimulacao.VariacaoPercentual := 0;
end;

// Reage à subida: registra no histórico e decide se a minhoca deve cair
// em seguida (somente quando ainda não saiu do buraco).
procedure TfrmMinhoca.SimulacaoSubiu(Sender: TObject);
begin
  RegistrarHistorico(Format('Subida %d: posi' + #231 + #227 + 'o = %d cm',
    [FSimulacao.QtdSubidas, FSimulacao.PosicaoAtual]));
  AtualizarInterface;

  if not FSimulacao.SaiuDoBuraco then
    FSimulacao.Cair;
end;

// Reage à queda: registra no histórico e aguarda 1s (ou o tempo configurado
// no TrackBar) via TTimer antes da próxima subida, sem travar a interface.
procedure TfrmMinhoca.SimulacaoCaiu(Sender: TObject);
begin
  RegistrarHistorico(Format('Queda: posi' + #231 + #227 + 'o = %d cm', [FSimulacao.PosicaoAtual]));
  AtualizarInterface;

  tmrQueda.Enabled := True;
end;

procedure TfrmMinhoca.SimulacaoFinalizou(Sender: TObject);
var
  EhRecorde: Boolean;
  Mensagem: string;
begin
  tmrQueda.Enabled := False;

  btnIniciar.Enabled := True;
  btnPausar.Enabled := False;
  HabilitarControlesDeEntrada(True);

  EhRecorde := (FMelhorQtdSubidas < 0) or (FSimulacao.QtdSubidas < FMelhorQtdSubidas);
  RegistrarRecordeSeNecessario;

  AtualizarInterface;

  RegistrarHistorico(Format('%s Parab' + #233 + 'ns! A minhoca saiu do buraco ap' + #243 + 's %d subidas! %s',
    [EMOJI_COMEMORACAO, FSimulacao.QtdSubidas, EMOJI_COMEMORACAO]));

  Mensagem := Format('%s Parab' + #233 + 'ns! %s' + sLineBreak + sLineBreak +
    'A minhoca conseguiu sair do buraco!' + sLineBreak +
    'Total de subidas: %d', [EMOJI_COMEMORACAO, EMOJI_COMEMORACAO, FSimulacao.QtdSubidas]);

  if EhRecorde then
    Mensagem := Mensagem + sLineBreak + sLineBreak + EMOJI_TROFEU + ' Novo recorde!';

  MessageDlg(Mensagem, mtInformation, [mbOK], 0);
end;

procedure TfrmMinhoca.AtualizarCorPainel;
begin
  if FSimulacao.SaiuDoBuraco then
  begin
    pnlStatus.Color := clLime;
    pnlStatus.Font.Style := [fsBold];
    pnlStatus.Caption := 'A minhoca saiu! ' + EMOJI_COMEMORACAO;
  end
  else if (FSimulacao.ProfundidadeBuraco > 0) and (FSimulacao.PosicaoAtual * 2 >= FSimulacao.ProfundidadeBuraco) then
  begin
    pnlStatus.Color := clYellow;
    pnlStatus.Font.Style := [];
    pnlStatus.Caption := 'Metade do caminho!';
  end
  else
  begin
    pnlStatus.Color := clBtnFace;
    pnlStatus.Font.Style := [];
    pnlStatus.Caption := '';
  end;
end;

procedure TfrmMinhoca.AtualizarInterface;
begin
  lblPosicaoAtual.Caption := Format('%d cm', [FSimulacao.PosicaoAtual]);
  lblQtdSubidas.Caption := IntToStr(FSimulacao.QtdSubidas);
  prgProgresso.Position := Round(FSimulacao.Ratio * 100);
  AtualizarCorPainel;
  DesenharGrafico;
end;

// Desenha a cena (solo, buraco e a minhoca) no TImage, de acordo com a
// posição exibida (que pode estar em transição suave entre dois valores
// reais da simulação). Usa apenas TCanvas, sem depender de arquivos de
// imagem externos.
procedure TfrmMinhoca.DesenharCena(APosicaoExibida: Double);
const
  Margem = 8;
  AlturaSolo = 14;
  AlturaSegmento = 14;
  QtdSegmentos = 4;
var
  Canvas: TCanvas;
  Largura, Altura: Integer;
  BuracoTop, BuracoBottom, BuracoEsquerda, BuracoDireita: Integer;
  Profundidade, Ratio: Double;
  CabecaX, CabecaY: Integer;
  i, SegX, SegY, Deslocamento: Integer;
begin
  Canvas := imgBuraco.Canvas;
  Largura := imgBuraco.Width;
  Altura := imgBuraco.Height;

  BuracoEsquerda := Margem;
  BuracoDireita := Largura - Margem;
  BuracoTop := Margem + AlturaSolo;
  BuracoBottom := Altura - Margem;

  // Fundo (céu)
  Canvas.Brush.Color := RGB(235, 245, 255);
  Canvas.FillRect(Rect(0, 0, Largura, Altura));

  // Faixa de grama = nível do solo (posição = profundidade, minhoca já saiu)
  Canvas.Brush.Color := RGB(76, 175, 80);
  Canvas.FillRect(Rect(0, Margem, Largura, BuracoTop));

  // Buraco (terra)
  Canvas.Brush.Color := RGB(121, 85, 72);
  Canvas.Pen.Color := RGB(78, 52, 46);
  Canvas.Rectangle(BuracoEsquerda, BuracoTop, BuracoDireita, BuracoBottom);

  if FSimulacao.ProfundidadeBuraco > 0 then
    Profundidade := FSimulacao.ProfundidadeBuraco
  else
    Profundidade := 1;

  Ratio := APosicaoExibida / Profundidade;
  if Ratio > 1 then
    Ratio := 1
  else if Ratio < 0 then
    Ratio := 0;

  CabecaX := (BuracoEsquerda + BuracoDireita) div 2;
  CabecaY := BuracoBottom - Round(Ratio * (BuracoBottom - BuracoTop));

  // Corpo da minhoca: segmentos empilhados a partir da cabeça, descendo
  // para o fundo do buraco, com leve ziguezague
  for i := QtdSegmentos - 1 downto 0 do
  begin
    SegY := CabecaY + i * AlturaSegmento;
    if SegY > BuracoBottom - 4 then
      Continue;

    if Odd(i) then
      Deslocamento := 6
    else
      Deslocamento := -6;
    SegX := CabecaX + Deslocamento;

    if Odd(i) then
      Canvas.Brush.Color := RGB(255, 182, 193)
    else
      Canvas.Brush.Color := RGB(233, 150, 122);
    Canvas.Pen.Color := RGB(150, 90, 90);
    Canvas.Ellipse(SegX - 9, SegY - 7, SegX + 9, SegY + 7);
  end;

  // Cabeça (por cima dos segmentos do corpo)
  Canvas.Brush.Color := RGB(233, 150, 122);
  Canvas.Pen.Color := RGB(150, 90, 90);
  Canvas.Ellipse(CabecaX - 9, CabecaY - 8, CabecaX + 9, CabecaY + 8);

  // Olhos
  Canvas.Brush.Color := clBlack;
  Canvas.Pen.Color := clBlack;
  Canvas.Ellipse(CabecaX - 5, CabecaY - 4, CabecaX - 2, CabecaY - 1);
  Canvas.Ellipse(CabecaX + 2, CabecaY - 4, CabecaX + 5, CabecaY - 1);

  // Confete comemorativo quando a minhoca já saiu do buraco
  if FSimulacao.SaiuDoBuraco then
  begin
    Canvas.Brush.Color := RGB(255, 193, 7);
    Canvas.Pen.Color := Canvas.Brush.Color;
    Canvas.Ellipse(BuracoEsquerda + 4, 0, BuracoEsquerda + 12, 6);

    Canvas.Brush.Color := RGB(3, 169, 244);
    Canvas.Pen.Color := Canvas.Brush.Color;
    Canvas.Ellipse(BuracoDireita - 14, 2, BuracoDireita - 6, 8);

    Canvas.Brush.Color := RGB(233, 30, 99);
    Canvas.Pen.Color := Canvas.Brush.Color;
    Canvas.Ellipse(CabecaX - 4, 0, CabecaX + 4, 6);
  end;

  imgBuraco.Invalidate;
end;

// Desenha um gráfico de linha simples com a posição da minhoca ao longo
// dos passos já realizados (histórico completo da simulação atual).
procedure TfrmMinhoca.DesenharGrafico;
const
  Margem = 8;
var
  Canvas: TCanvas;
  Largura, Altura: Integer;
  Profundidade: Integer;
  Historico: TList<Integer>;
  i, X, Y: Integer;
  RatioValor: Double;
begin
  Canvas := imgGrafico.Canvas;
  Largura := imgGrafico.Width;
  Altura := imgGrafico.Height;

  Canvas.Brush.Color := RGB(250, 250, 250);
  Canvas.Pen.Color := RGB(200, 200, 200);
  Canvas.Rectangle(Rect(0, 0, Largura, Altura));

  Profundidade := FSimulacao.ProfundidadeBuraco;
  Historico := FSimulacao.HistoricoPosicoes;

  if (Profundidade <= 0) or (Historico.Count = 0) then
  begin
    imgGrafico.Invalidate;
    Exit;
  end;

  // Linha tracejada indicando o nível de saída (profundidade total)
  Canvas.Pen.Color := RGB(76, 175, 80);
  Canvas.Pen.Style := psDash;
  Canvas.MoveTo(Margem, Margem);
  Canvas.LineTo(Largura - Margem, Margem);
  Canvas.Pen.Style := psSolid;

  Canvas.Pen.Color := RGB(233, 150, 122);
  Canvas.Pen.Width := 2;

  for i := 0 to Historico.Count - 1 do
  begin
    if Historico.Count > 1 then
      X := Margem + Round(i * (Largura - 2 * Margem) / (Historico.Count - 1))
    else
      X := Margem;

    RatioValor := Historico[i] / Profundidade;
    if RatioValor > 1 then
      RatioValor := 1
    else if RatioValor < 0 then
      RatioValor := 0;

    Y := Altura - Margem - Round(RatioValor * (Altura - 2 * Margem));

    if i = 0 then
      Canvas.MoveTo(X, Y)
    else
      Canvas.LineTo(X, Y);
  end;

  Canvas.Pen.Width := 1;
  imgGrafico.Invalidate;
end;

procedure TfrmMinhoca.RegistrarHistorico(const AMensagem: string);
begin
  lstHistorico.Items.Add(AMensagem);
  lstHistorico.ItemIndex := lstHistorico.Items.Count - 1;
end;

procedure TfrmMinhoca.HabilitarControlesDeEntrada(AHabilitar: Boolean);
begin
  edtProfundidade.Enabled := AHabilitar;
  edtSubida.Enabled := AHabilitar;
  edtQueda.Enabled := AHabilitar;
end;

procedure TfrmMinhoca.btnExportarClick(Sender: TObject);
begin
  if lstHistorico.Items.Count = 0 then
  begin
    ShowMessage('N' + #227 + 'o h' + #225 + ' hist' + #243 + 'rico para exportar ainda.');
    Exit;
  end;

  if dlgSalvarHistorico.Execute then
    lstHistorico.Items.SaveToFile(dlgSalvarHistorico.FileName);
end;

procedure TfrmMinhoca.btnLimparClick(Sender: TObject);
begin
  // Interrompe qualquer simulação em andamento e restaura o estado inicial
  tmrQueda.Enabled := False;
  tmrAnimacao.Enabled := False;
  FPausado := False;
  FDisplayPosicao := 0;

  FSimulacao.Resetar;

  lstHistorico.Clear;

  btnIniciar.Enabled := True;
  btnPausar.Enabled := False;
  btnPausar.Caption := 'Pausar';
  HabilitarControlesDeEntrada(True);

  DefinirValoresPadrao;
  chkAleatorio.Checked := False;
  FSimulacao.VariacaoPercentual := 0;
  trkVelocidade.Position := 1000;
  tmrQueda.Interval := 1000;
  lblVelocidadeValor.Caption := '1000 ms';

  AtualizarInterface;
  DesenharCena(0);
end;

function TfrmMinhoca.NomeArquivoConfig: string;
begin
  Result := ChangeFileExt(Application.ExeName, '.ini');
end;

procedure TfrmMinhoca.CarregarConfiguracao;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(NomeArquivoConfig);
  try
    edtProfundidade.Text := Ini.ReadString('Parametros', 'Profundidade', '20');
    edtSubida.Text := Ini.ReadString('Parametros', 'Subida', '5');
    edtQueda.Text := Ini.ReadString('Parametros', 'Queda', '3');
    chkAleatorio.Checked := Ini.ReadBool('Parametros', 'Aleatorio', False);
    trkVelocidade.Position := Ini.ReadInteger('Parametros', 'VelocidadeMs', 1000);

    FMelhorQtdSubidas := Ini.ReadInteger('Recorde', 'MenorQtdSubidas', -1);
  finally
    Ini.Free;
  end;

  FSimulacao.VariacaoPercentual := IfThen(chkAleatorio.Checked, 20, 0);
  AtualizarLabelRecorde;
end;

procedure TfrmMinhoca.SalvarConfiguracao;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(NomeArquivoConfig);
  try
    Ini.WriteString('Parametros', 'Profundidade', edtProfundidade.Text);
    Ini.WriteString('Parametros', 'Subida', edtSubida.Text);
    Ini.WriteString('Parametros', 'Queda', edtQueda.Text);
    Ini.WriteBool('Parametros', 'Aleatorio', chkAleatorio.Checked);
    Ini.WriteInteger('Parametros', 'VelocidadeMs', trkVelocidade.Position);
  finally
    Ini.Free;
  end;
end;

procedure TfrmMinhoca.AtualizarLabelRecorde;
begin
  if FMelhorQtdSubidas < 0 then
    lblRecorde.Caption := 'Recorde: nenhum ainda'
  else
    lblRecorde.Caption := Format('Recorde: %d subidas', [FMelhorQtdSubidas]);
end;

procedure TfrmMinhoca.RegistrarRecordeSeNecessario;
var
  Ini: TIniFile;
begin
  if (FMelhorQtdSubidas >= 0) and (FSimulacao.QtdSubidas >= FMelhorQtdSubidas) then
    Exit;

  FMelhorQtdSubidas := FSimulacao.QtdSubidas;
  AtualizarLabelRecorde;

  Ini := TIniFile.Create(NomeArquivoConfig);
  try
    Ini.WriteInteger('Recorde', 'MenorQtdSubidas', FMelhorQtdSubidas);
  finally
    Ini.Free;
  end;
end;

end.
