unit Main;

{$WARN SYMBOL_PLATFORM OFF}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, CheckLst, XPMan, ExtCtrls, ComCtrls, shellapi, Menus,
  FileCtrl;

type
  TForm1 = class(TForm)
    CheckListBox1: TCheckListBox;
    EdtProjectDir: TEdit;
    XPManifest1: TXPManifest;
    HeaderControl1: THeaderControl;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel4: TPanel;
    LblCountSize: TLabel;
    BtnBrowse: TButton;
    Label2: TLabel;
    Label3: TLabel;
    MainMenu1: TMainMenu;
    Projets1: TMenuItem;
    Ouvrirunprojet1: TMenuItem;
    N1: TMenuItem;
    Nettoyerleprojet1: TMenuItem;
    Vue1: TMenuItem;
    Rafraichir1: TMenuItem;
    Explorerleprojet1: TMenuItem;
    N2: TMenuItem;
    AproposdeDEPOC1: TMenuItem;
    Panel3: TPanel;
    BtnCleanProject: TButton;
    BtnRefresh: TButton;
    BtnExplore: TButton;
    procedure FormCreate(Sender: TObject);
    procedure CheckListBox1DrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure FormResize(Sender: TObject);
    procedure CheckListBox1ClickCheck(Sender: TObject);
    procedure BtnCleanProjectClick(Sender: TObject);
    procedure BtnRefreshClick(Sender: TObject);
    procedure BtnBrowseClick(Sender: TObject);
    procedure BtnExploreClick(Sender: TObject);
    procedure AproposdeDEPOC1Click(Sender: TObject);
    procedure Projets1Click(Sender: TObject);
  private
  public
    procedure ScanProject(const PrDr : string);
    procedure InitiateScan;
  end;

var
  Form1      : TForm1;
  AppDir,                    { repertoire de l'application }
  ProjectDir : string;       { repertoire du projet        }
  TotalSize  : int64 = 0;    { taille totale du projet     }

implementation

{$R *.dfm}

uses DepocTools, About;


{ ScanProject ------------------------------------------------------------------------------------ }
{ Methode recurssive qui explorer le repertoire et tout les sous-repertoires de ce dernier         }
procedure TForm1.ScanProject(const PrDr : string);
var SRC : TSearchrec;  { voir aide delphi : TSearchRec }
    SDN : string;      { nom du sous-repertoire moins le repertoire du projet }
    LC,IDS : integer;  { LC compteur pour processmessage | IDS index de l'element ajouté }
begin
  { si le repertoire existe }
  if DirectoryExists(PrDr) then begin
     { init du compteur a 0 }
     LC  := 0;
     { on recupere le nom du sous-repertoire }
     SDN := copy(PrDr,length(ProjectDir)+1,length(PrDr));

     try
       { on recherche le premier fichier ou repertoire }
       if findfirst(PrDr+'*.*',faAnyFile,SRC) = 0 then begin
          { entrée dans la boucle }
          repeat
            { on incremente le compteur }
            inc(LC);

            { si le nom est different de . ou .. (root directory) }
            if (SRC.Name <> '.') and (src.Name <> '..') then begin

               { si l'attributs nous indique qu'il s'agit d'un repertoire }
               if (SRC.Attr and faDirectory) <> 0 then begin
                  { on recursse ScanProject sur le nouveau repertoire }
                  ScanProject(PrDr+SRC.Name+'\');
               end else

               { si l'attribut nous indique qu'il s'agit d'un fichier }
               if not ((SRC.Attr and faVolumeID) <> 0) then begin
                  { on ajoute l'element et on recupere l'index dans IDS }
                  IDS := CheckListBox1.Items.Add(SDN+SRC.Name);
                  { si il s'agit d'un fichier a supprimer }
                  if HaveBadExt(SRC.Name) or IsBadFile(SRC.Name) then begin
                     { on le coche par defaut }
                     CheckListBox1.Checked[IDS] := true;
                  end;
               end;
            end;
            { tout les dix passages on appel application.processmessage pour rafraichir
              l'affichage }
            if (LC mod 10) = 0 then begin
               application.ProcessMessages;
            end;

          { la boucle se termine quand FindNext ne trouve plus rien }
          until findnext(SRC) <> 0;
       end;
     finally
       { et enfin on ferme SRC }
       FindClose(SRC);
     end;
  end;
end;


{ InitiateScan ----------------------------------------------------------------------------------- }
{ initialise l'exploration du projet, on appel cette methode pour tout nouveau projet a explorer   }
procedure TForm1.InitiateScan;
var N : integer; { compteur pour la boucle }
begin
  { on efface la liste }
  CheckListBox1.Clear;
  { on scan le projet }
  ScanProject(ProjectDir);
  { on rafraichis la liste }
  CheckListBox1.Refresh;

  { on remet TotalSize a zero et on recalcul la taille totale }
  TotalSize := 0;
  for N := 0 to CheckListBox1.count-1 do
     TotalSize := TotalSize + GetFileSize(ProjectDir+CheckListBox1.Items[N]);
  { enfin, on affiche les informations dans le label LblCountSize }
  LblCountSize.Caption := ThousandSep(CheckListBox1.Count)+' fichiers : '+
                          ThousandSep(TotalSize)+' Octets';

  BtnCleanProject.Enabled := (CheckListBox1.Count > 0);
  BtnExplore.Enabled      := DirectoryExists(ProjectDir);
end;

{ FormCreate ------------------------------------------------------------------------------------- }
{ creation de la fiche }
procedure TForm1.FormCreate(Sender: TObject);
begin
  { on recupere le repertoire de l'application }
  AppDir := ExtractFilePath(Application.ExeName);

  { on doublebufferize HeaderControl ... inutile en fait }
  //headercontrol1.DoubleBuffered := true;
end;


{ CheckListBox1DrawItem -------------------------------------------------------------------------- }
{ Dessin des elements dans la checklist, comme toujours on remarque l'erreur faite par borland
  avec la variable Rect qui cache la methode Rect de l'unité Classes d'ou la methode SRect dans
  l'unité DepocTools }
procedure TForm1.CheckListBox1DrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
var Fe,S,SzS   : string;   { Extention du fichier | Chaine de l'item | Taille du fichier (chaine) }
    Sz         : cardinal; { taille du fichier }
    IcF        : TIcon;    { icone du fichier  }
    hIcF       : HICON;    { handle de l'icone 16x16, Nullp ne sert a rien }
    Rect2      : TRect;    { TRect temporaire pour la zone de dessin }
begin
  { on recupere la chaine a l'index en cours }
  S   := CheckListBox1.Items[index];
  { on recupere la taille du fichier }
  Sz  := GetFileSize(ProjectDir+S);
  { on convertis en chaine }
  SzS := ThousandSep(Sz)+' Octets';
  { on recupere l'extention en minuscule }
  Fe  := lowercase(ExtractFileExt(S));

  with CheckListBox1.Canvas do begin
       { si l'element est selectionné et que l'element est selectionné :$
         Ouaaai! super explication!
         Si l'element est selectionné dans la liste et que l'element est coché }
       if (not (odSelected in State)) and CheckListBox1.Checked[index] then
          Brush.Color := $e0e0ff;

       { on efface la zone de dessins }
       fillrect(rect);

       { on recupere l'icone du fichier }
       GetAssociatedIcons(ProjectDir+S, True, hIcF);
       if hIcF <> INVALID_HANDLE_VALUE then begin
          IcF := nil;
          try
            { on crée l'icone }
            IcF        := TIcon.Create;
            { on lui assigne le handle recupéré dans pIcF }
            IcF.Handle := hIcF;
            { on le dessine dans le canvas }
            draw(rect.Left, rect.Top, IcF);
          finally
            { on libere }
            IcF.Free;
          end;
       end;

       { si l'element en cours n'est pas selectionné dans la liste }
       if not (odSelected in State) then begin
          { si il a une bonne extention (fichier utile au projet) }
          if HaveGoodExt(S) then
             { on ecrit en bleu }
             font.Color := $FF0000
          else

          { si il a une mauvaise extention }
          if HaveBadExt(S) then
             { on ecrit en rouge }
             font.Color := $000095;
       end;
       { on recupere la zone et on ecrit le nom du fichier }
       Rect2 := Classes.Rect( Rect.Left+18,
                              Rect.Top,
                              Rect.Left+HeaderControl1.Sections[0].Width-18,
                              Rect.Bottom
                            );
       TextRect(Rect2,rect2.Left,rect2.Top,S);

       { si l'element en cours n'est pas selectionné dans la liste }
       if not (odSelected in State) then begin
          { selon la taille du fichier la couleur change }
          if Sz < 65535 then
             font.Color := $009500
          else
          if Sz < 131070 then
             font.Color := $000095
          else
          if Sz < 262140 then
             font.Color := $0000C4
          else
             font.Color := $0000FF;
       end;

       { on recupere la zone et on ecrit la taille du fichier }
       Rect2 := Classes.Rect( Rect.left+HeaderControl1.Sections[0].Width,
                              Rect.Top,
                              Rect.Right,
                              Rect.Bottom
                            );
       TextRect(Rect2,Rect2.Right-TextWidth(SzS)-8, Rect.Top, SzS);

       { enfin, on dessine une ligne de separation Nom/Taille }
       pen.Color := clBtnFace;
       moveto(HeaderControl1.Sections[0].Width-1,Rect.Top);
       lineto(HeaderControl1.Sections[0].Width-1,Rect.Bottom);
  end;
end;


{ FormResize ------------------------------------------------------------------------------------- }
{ redimensionnement de la fenetre }
procedure TForm1.FormResize(Sender: TObject);
begin
  { on redimensionne la colone "Nom" }
  with HeaderControl1 do begin
       Sections[0].Width := Width - Sections[1].Width;
  end;

 { pour plus de confort on rafraichis la liste quand la fenetre est redimensionnée sinon,
  bonjour la catastrophe }
  CheckListBox1.Refresh;
end;


{ CheckListBox1ClickCheck ------------------------------------------------------------------------ }
{ quand on coche ou decoche un element de la liste }
procedure TForm1.CheckListBox1ClickCheck(Sender: TObject);
var Index : integer;
begin
  { on recupere l'index }
  index := CheckListBox1.ItemIndex;

  { si il s'agit d'un fichier utile au projet on affiche une alerte }
  if CheckListBox1.Checked[index] and HaveGoodExt(CheckListBox1.Items[index]) then begin
     if MessageDlg( 'Ce fichier semble necessaire au projet,'+#13+#10+
                    'Desirez vous vraiment supprimer ce fichier ?',
                    mtConfirmation,[mbYes,mbNo],0) = mrNo then
        CheckListBox1.Checked[index] := false;
  end;
end;


{ BtnCleanProjectClick --------------------------------------------------------------------------- }
{ c'est partis! on nettois le projet }
procedure TForm1.BtnCleanProjectClick(Sender: TObject);
var N : integer;
begin
  { si aucun elements dans la liste, on s'en vas }
  if CheckListBox1.Count = 0 then exit;

  { on demande confirmation d'abord }
  if MessageDlg( 'Supprimer les fichiers sélectionnés ?'+#13+#10+
                 '(Action irreverssible!)',
                 mtConfirmation,[mbYes,mbNo],0) = mrYes then begin

     { c'est ok, on efface tout les fichier cochés }
     for N := 0 to CheckListBox1.Count-1 do begin
         if CheckListBox1.Checked[N] then
            DeleteFile(ProjectDir+CheckListBox1.Items[N]);
     end;

     { on rafraichis la liste }
     InitiateScan;
  end;
end;


{ BtnRefreshClick -------------------------------------------------------------------------------- }
procedure TForm1.BtnRefreshClick(Sender: TObject);
begin
  { besoin d'explication ici ? }
  InitiateScan;
end;

{ BtnBrowseClick --------------------------------------------------------------------------------- }
{ selection du repertoire du projet }
{ <Cirec><12/06/2006> }
procedure TForm1.BtnBrowseClick(Sender: TObject);
var DResult : string;
begin
  If SelectDirectory('Selectionnez un dossier','',DResult) Then Begin
     ProjectDir         := IncludeTrailingBackSlash(DResult);
     EdtProjectDir.Text := ProjectDir;
     InitiateScan;
  end;
end;

{ BtnExploreClick -------------------------------------------------------------------------------- }
{ lance un explorateur sur le repertoire du projet ouvert dans Depoc }
procedure TForm1.BtnExploreClick(Sender: TObject);
begin
  ExploreDirectory(ProjectDir);
end;

{ AproposdeDEPOC1Click --------------------------------------------------------------------------- }
{ affiche la fenetre d'a propos (FrmAbout) }
procedure TForm1.AproposdeDEPOC1Click(Sender: TObject);
begin
  { FrmAbout (unité About) s'utilise comme une OpenDialog, bien que cela soit inutile ici }
  FrmAbout.Execute;
end;

procedure TForm1.Projets1Click(Sender: TObject);
begin
  ExplorerLeProjet1.Enabled := DirectoryExists(ProjectDir);
  NettoyerLeProjet1.Enabled := (CheckListBox1.Count > 0);
end;

end.
