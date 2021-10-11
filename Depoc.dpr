program Depoc;

uses
  Forms,
  SysUtils,
  Dialogs,
  main in 'Main.pas' {Form1},
  DepocTools in 'DepocTools.pas',
  About in 'About.pas' {FrmAbout};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'DePrCl';
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TFrmAbout, FrmAbout);
  { si un parametre est passé en ligne de commande on lance un scan au demarrage de l'application }
  if (ParamCount <> 0) and (DirectoryExists(paramstr(1))) then begin
     ProjectDir := ExtractFilePath(paramstr(1));
     Form1.EdtProjectDir.Text := ProjectDir;
     Form1.InitiateScan;
  end;

  Application.Run;
end.
