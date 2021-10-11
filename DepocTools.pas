unit DepocTools;

interface

uses windows, sysutils, registry, shellapi, graphics, classes;

type
  TVersionExploder = record
    case integer of
      0 : (code : cardinal);
      1 : (Build, Release, Minor, Major : byte);
  end;
  TVersionDate = record
    Year,Month,Day : word;
  end;

const                               { major | minor | release | build }
  D_Version    : TVersionExploder = (Code : $01000002);
  D_CompilDate : TVersionDate     = (Year : 2006; Month : 6; Day : 12);


{ ThousandSep ------------------------------------------------------------------------------------ }
{ renvois un chiffre avec separateur de milliers dans une chaine }
function ThousandSep(const V : int64) : string;


{ ------------------------------------------------------------------------------------------------ }
{ test des extentions de fichiers }
function HaveGoodExt(const FileName : string) : boolean;
function HaveBadExt(const FileName : string) : boolean;
function IsBadFile(const FileName : string) : boolean;


{ GetAssociatedIcons ----------------------------------------------------------------------------- }
procedure GetAssociatedIcons(const AExtension: string;const ASmall: Boolean; out ICH : HIcon);

{ GetFileSize ------------------------------------------------------------------------------------ }
{ je ne devrais pas avoir a vous expliquer ce que fait cette fonction. }
function GetFileSize(const FileName : string) : cardinal;

{ ExploreDirectory ------------------------------------------------------------------------------- }
{ Lance un explorateur sur le repertoire passé en parametre }
function ExploreDirectory(const Path : string) : boolean;

{ ------------------------------------------------------------------------------------------------ }

const
  { extentions valides, invallides
    j'ai utilisé ce systeme pour aller plus vite qu'avec un tableau de chaine
    ici on utiliserat Pos() pour rechercher l'extention dans la chaine }
  GoodExt  : string = '#.dpk#.dpr#.pas#.res#.dcr#.dfm#.bdsproj#';
  BadExt   : string = '#.dcu#.exe#.dof#.cfg#.ddp#.dsk#.map#';
  BadTilde : string = '.~';
  BadFiles : string = '#Thumbs.db#';

{ ------------------------------------------------------------------------------------------------ }


implementation

{ ------------------------------------------------------------------------------------------------ }

function ThousandSep(const V : int64) : string;
var x,c,s : integer;
begin
  { on convertis V en chaine }
  result := inttostr(V);
  { si on est inferieur a 4 on sort }
  if length(result) < 4 then exit;
  c := 0;
  s := 1;
  { de la fin au debut }
  for x := length(result) downto 1 do begin
      { si on a compter 3 lettres }
      if (s mod 3) = 0 then begin
         { on insere un espace a la position }
         Insert(' ',result,x-c);
         s := 1;
         inc(c);
      end;
      inc(s);
  end;
  { on trim le resultat pour eviter d'avoir un espace au debut de la chaine }
  result := trim(result);
end;

{ ------------------------------------------------------------------------------------------------ }

function HaveGoodExt(const FileName : string) : boolean;
begin
  result := (pos('#'+LowerCase(ExtractFileExt(FileName))+'#',GoodExt) <> 0);
end;

function HaveBadExt(const FileName : string) : boolean;
var FExt : string;
begin
  FExt := LowerCase(ExtractFileExt(FileName));
  result := (pos('#'+FExt+'#',BadExt) <> 0) or
            (pos(BadTilde,FExt) = 1);
end;

function IsBadFile(const FileName : string) : boolean;
begin
  result := (pos('#'+LowerCase(ExtractFileName(FileName))+'#',BadFiles) <> 0);
end;

{ ------------------------------------------------------------------------------------------------ }
function GetFileSize(const FileName : string) : cardinal;
var SRec : TSearchRec;
begin
  try
    if SysUtils.FindFirst(FileName,faAnyFile,SRec) = 0 then
       result := SRec.Size
    else
       result := 0;
  finally
    SysUtils.FindClose(SRec);
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
{ <Cirec> <12/06/2006> }
procedure GetAssociatedIcons(const AExtension: string;const ASmall: Boolean; out ICH : HIcon);
var
  Info  : TSHFileInfo;
  Flags : Cardinal;
begin
  if ASmall then
    Flags := SHGFI_ICON or SHGFI_SMALLICON or SHGFI_USEFILEATTRIBUTES
  else
    Flags := SHGFI_ICON or SHGFI_LARGEICON or SHGFI_USEFILEATTRIBUTES;

  SHGetFileInfo(PChar(AExtension), FILE_ATTRIBUTE_NORMAL, Info, SizeOf(TSHFileInfo), Flags);
  ICH := Info.hIcon;
end;

{ ------------------------------------------------------------------------------------------------ }

function ExploreDirectory(const Path : string) : boolean;
begin
  { un simple ShellExecute sur Explorer.exe }
  result := false;
  if not DirectoryExists(Path) then exit;
  result := ShellExecute( 0, 'open',
                pchar('explorer.exe'),
                pchar(Path),
                pchar(Path),
                SW_SHOW
            ) <> INVALID_HANDLE_VALUE;
end;

end.
