unit uMain;

interface

uses
  SysUtils,

  uPipedExternalApplication,
  uConsoleApplication;

type
  TMain = class(TConsoleApplication)
  private
    FEngineApplication: TPipedExternalApplication;

    procedure OnReadFromEngine(const ALine: string);

    function GetFileName: TFileName;
    procedure SetFileName(const Value: TFileName);
    procedure TestCommands;
    procedure TestTimeCommand;
    procedure TestLevelCommand;
    procedure MainLoop;
    procedure LogIfChanged(OriginalCommand: string; ModifiedCommand: string);
    function CorrectCommandNoError(const AOriginalCommand: string): string;
  protected
    procedure OnRun; override;
  public
    constructor Create;
    destructor Destroy; override;

    property FileName: TFileName read GetFileName write SetFileName;
  end;

implementation

uses
  uTypes,
  uLog,

  uCorrectCommands;

{ TMain }

constructor TMain.Create;
begin
  inherited;
  TestCommands;

  FEngineApplication := TPipedExternalApplication.Create;
  FEngineApplication.OnReadLine := OnReadFromEngine;
end;

destructor TMain.Destroy;
begin
  try
    FEngineApplication.Free;
  finally
    inherited;
  end;
end;

function TMain.CorrectCommandNoError(const AOriginalCommand: string): string;
begin
  try
    Result := CorrectCommands(AOriginalCommand);
  except
    on E: Exception do
    begin
      MainLog.LogException(E);
      Result := AOriginalCommand;
    end;
  end;
end;

procedure TMain.LogIfChanged(OriginalCommand: string; ModifiedCommand: string);
begin
  if LogInformation then
  begin
    if ModifiedCommand <> OriginalCommand then
    begin
      MainLog.Add('> ' + ModifiedCommand + ' [' + OriginalCommand + ']', mlInformation);
    end
    else
      MainLog.Add('> ' + OriginalCommand, mlInformation);
  end;
end;

procedure TMain.MainLoop;
var
  OriginalCommand: string;
  ModifiedCommand: string;
begin
  while not Terminated do
  begin
    // <summary>Blocking read from engine</summary>
    Readln(OriginalCommand);
    if OriginalCommand = 'quit' then
    begin
      Terminate;
    end;

    if Assigned(FEngineApplication) and Assigned(FEngineApplication.StdIn) then
    begin
      ModifiedCommand := CorrectCommandNoError(OriginalCommand);
      LogIfChanged(OriginalCommand, ModifiedCommand);

      // <summary>Write to engine</summary>
      FEngineApplication.WriteLine(ModifiedCommand);
    end;
  end;
end;

procedure TMain.TestLevelCommand;
begin
  Assert(CorrectCommands('level 0 15 0:20') = 'level 0 15:00 19');
  Assert(CorrectCommands('level 0 15 20') = 'level 0 15:00 19');
  Assert(CorrectCommands('level 0 15:0 20') = 'level 0 15:00 19');
  Assert(CorrectCommands('level 0 15:0 3') = 'level 0 15:00 2');
  Assert(CorrectCommands('level 0 15:0 2') = 'level 0 15:00 1');
  Assert(CorrectCommands('level 0 15:0 1') = 'level 0 15:00 0');
  Assert(CorrectCommands('level 0 15:0 0') = 'level 0 15:00 0');
end;

procedure TMain.TestTimeCommand;
begin
  Assert(CorrectCommands('time 141.0') = 'time 10');
  Assert(CorrectCommands('time 641.0') = 'time 341');
end;

procedure TMain.TestCommands;
begin
  TestTimeCommand;
  TestLevelCommand;
end;

function TMain.GetFileName: TFileName;
begin
  Result := FEngineApplication.FileName;
end;

procedure TMain.OnReadFromEngine(const ALine: string);
begin
  if LogInformation then
    MainLog.Add('< ' + string(ALine), mlInformation);
  Writeln(ALine);
  Flush(Output);
end;

procedure TMain.OnRun;
begin
  inherited;

  FEngineApplication.Execute;
  FEngineApplication.CheckErrorCode;
  MainLoop;
end;

procedure TMain.SetFileName(const Value: TFileName);
begin
  if Value <> FEngineApplication.FileName then
  begin
    FEngineApplication.FileName := Value;
    FEngineApplication.CurrentDirectory := ExtractFilePath(Value);
  end;
end;

end.
