program PseudoAdapter;

{$R *.RES}

uses
  uFiles,
  uMain in 'uMain.pas',
  uCorrectCommands in 'uCorrectCommands.pas';

var
  Main: TMain;
begin
  Main := TMain.Create;
  try
    Main.FileName := WorkDir + 'pseudo_07c.exe';
    Main.Run;
  finally
    Main.Free;
  end;
end.
