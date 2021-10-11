unit About;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, jpeg, ExtCtrls, StdCtrls, ComCtrls;

type
  TFrmAbout = class(TForm)
    ButtonOk: TButton;
    LblVersion: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    procedure FormCreate(Sender: TObject);
  private
  public
    function Execute : boolean;
  end;

var
  FrmAbout   : TFrmAbout;

implementation

{$R *.dfm}
uses DepocTools;

const
  Infos : string = 'DePoC v%d.%d.%d.%d - %.2d/%.2d/%d';

function TFrmAbout.Execute : boolean;
begin
  result := (ShowModal = mrOk);
end;

procedure TFrmAbout.FormCreate(Sender: TObject);
begin

  LblVersion.Caption := format(Infos,
                        [ D_Version.Major,D_Version.Minor,D_Version.Release,D_Version.Build,
                          D_CompilDate.Day, D_CompilDate.Month, D_CompilDate.Year]);
end;


end.
