object frmMinhoca: TfrmMinhoca
  Left = 0
  Top = 0
  Caption = 'Simula'#231#227'o - Minhoca no Buraco'
  ClientHeight = 620
  ClientWidth = 700
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 15
  object lblProfundidadeCaption: TLabel
    Left = 24
    Top = 24
    Width = 160
    Height = 15
    Caption = 'Profundidade do buraco (cm):'
  end
  object lblSubidaCaption: TLabel
    Left = 24
    Top = 56
    Width = 76
    Height = 15
    Caption = 'Subida (cm):'
  end
  object lblQuedaCaption: TLabel
    Left = 24
    Top = 88
    Width = 72
    Height = 15
    Caption = 'Queda (cm):'
  end
  object lblVelocidadeCaption: TLabel
    Left = 24
    Top = 146
    Width = 199
    Height = 15
    Caption = 'Velocidade da pausa ap'#243's queda:'
  end
  object lblVelocidadeValor: TLabel
    Left = 292
    Top = 172
    Width = 47
    Height = 15
    Caption = '1000 ms'
  end
  object lblPosicaoCaption: TLabel
    Left = 24
    Top = 244
    Width = 82
    Height = 15
    Caption = 'Posi'#231#227'o atual:'
  end
  object lblPosicaoAtual: TLabel
    Left = 160
    Top = 244
    Width = 40
    Height = 15
    Caption = '0 cm'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblSubidasCaption: TLabel
    Left = 24
    Top = 268
    Width = 132
    Height = 15
    Caption = 'Quantidade de subidas:'
  end
  object lblQtdSubidas: TLabel
    Left = 160
    Top = 268
    Width = 8
    Height = 15
    Caption = '0'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblRecorde: TLabel
    Left = 24
    Top = 320
    Width = 122
    Height = 15
    Caption = 'Recorde: nenhum ainda'
  end
  object lblGraficoCaption: TLabel
    Left = 520
    Top = 58
    Width = 148
    Height = 15
    Caption = 'Posi'#231#227'o ao longo do tempo'
  end
  object edtProfundidade: TEdit
    Left = 200
    Top = 21
    Width = 80
    Height = 23
    TabOrder = 0
    Text = '20'
  end
  object edtSubida: TEdit
    Left = 200
    Top = 53
    Width = 80
    Height = 23
    TabOrder = 1
    Text = '5'
  end
  object edtQueda: TEdit
    Left = 200
    Top = 85
    Width = 80
    Height = 23
    TabOrder = 2
    Text = '3'
  end
  object chkAleatorio: TCheckBox
    Left = 24
    Top = 118
    Width = 320
    Height = 17
    Caption = 'Varia'#231#227'o aleat'#243'ria ('#177'20%) na subida/queda (opcional)'
    TabOrder = 3
    OnClick = chkAleatorioClick
  end
  object trkVelocidade: TTrackBar
    Left = 24
    Top = 166
    Width = 260
    Height = 30
    Max = 3000
    Min = 200
    Frequency = 100
    Position = 1000
    TabOrder = 4
    ThumbLength = 16
    OnChange = trkVelocidadeChange
  end
  object btnIniciar: TButton
    Left = 24
    Top = 204
    Width = 90
    Height = 25
    Caption = 'Iniciar'
    TabOrder = 5
    OnClick = btnIniciarClick
  end
  object btnPausar: TButton
    Left = 120
    Top = 204
    Width = 90
    Height = 25
    Caption = 'Pausar'
    Enabled = False
    TabOrder = 6
    OnClick = btnPausarClick
  end
  object btnLimpar: TButton
    Left = 216
    Top = 204
    Width = 110
    Height = 25
    Caption = 'Limpar / Reiniciar'
    TabOrder = 7
    OnClick = btnLimparClick
  end
  object prgProgresso: TProgressBar
    Left = 24
    Top = 292
    Width = 320
    Height = 20
    TabOrder = 8
  end
  object btnExportar: TButton
    Left = 24
    Top = 344
    Width = 180
    Height = 25
    Caption = 'Exportar hist'#243'rico...'
    TabOrder = 9
    OnClick = btnExportarClick
  end
  object lstHistorico: TListBox
    Left = 24
    Top = 380
    Width = 320
    Height = 216
    ItemHeight = 15
    TabOrder = 10
  end
  object pnlStatus: TPanel
    Left = 360
    Top = 24
    Width = 316
    Height = 24
    Caption = ''
    TabOrder = 11
  end
  object imgBuraco: TImage
    Left = 360
    Top = 58
    Width = 140
    Height = 434
  end
  object imgGrafico: TImage
    Left = 520
    Top = 76
    Width = 156
    Height = 416
  end
  object tmrQueda: TTimer
    Enabled = False
    Interval = 1000
    OnTimer = tmrQuedaTimer
    Left = 448
    Top = 24
  end
  object tmrAnimacao: TTimer
    Enabled = False
    Interval = 30
    OnTimer = tmrAnimacaoTimer
    Left = 496
    Top = 24
  end
  object dlgSalvarHistorico: TSaveDialog
    DefaultExt = 'txt'
    Filter = 'Arquivo de texto (*.txt)|*.txt|Todos os arquivos (*.*)|*.*'
    Title = 'Exportar hist'#243'rico da simula'#231#227'o'
    Left = 544
    Top = 24
  end
end
