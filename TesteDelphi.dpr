program TesteDelphi;

uses
  Vcl.Forms,
  uMinhocaForm in 'uMinhocaForm.pas' {frmMinhoca},
  uSimulacaoMinhoca in 'uSimulacaoMinhoca.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMinhoca, frmMinhoca);
  Application.Run;
end.
