unit uCorrectCommands;

interface

function CorrectCommands(const ALine: string): string;

implementation

uses
  Velthuis.BigDecimals,

  uTypes,
  uStrings,
  uInputFormat,
  uLevelCommandParser;

function CorrectTimeCommand(const AParameter: string): string;
var
  OldTime: BigDecimal;
  NewTime: BigDecimal;
  MaximalCentiSeconds: BigDecimal;
const
  /// <summary>centi-seconds, 3 seconds</summary>
  OffsetRemainTimeLag = 300;

  /// <summary>centi-seconds, 100 milliseconds</summary>
  MinimalTime = 10;

  LichessCorrespondence = '214748364.7';
begin
  if AParameter = LichessCorrespondence then
  begin
    // Lichess correspondence hotfix, set time to 15 minutes
    NewTime := 15 * 60 * 100;
  end
  else
  begin
    // Set 10 years as maximum
    MaximalCentiSeconds := 100 * 60 * 60 * 24;
    MaximalCentiSeconds := MaximalCentiSeconds * 365 * 10;

    OldTime := StrToValBD(AParameter, False, -MaximalCentiSeconds, 0, MaximalCentiSeconds);
    NewTime := OldTime - OffsetRemainTimeLag;
    if NewTime < MinimalTime then
      NewTime := MinimalTime;
  end;
  Result := 'time ' + NewTime.ToString;
end;

function CorrectLevelCommand(const AParameters: string): string;
var
  LevelCommandParser: TLevelCommandParser;
const
  /// <summary>seconds, 1 second</summary>
  OffsetMoveIncrementTimeLag = 1;
begin
  LevelCommandParser := TLevelCommandParser.Create;
  try
    LevelCommandParser.Parse(AParameters);

    // Pseudo time management bug
    // if time command value is less then move increment in level command, Pseudo uses move increment for time limit
    // Hotfix: decrement move increment
    if LevelCommandParser.MoveIncrementTime.SecondsAsF >= OffsetMoveIncrementTimeLag then
      LevelCommandParser.MoveIncrementTime.SecondsAsF := LevelCommandParser.MoveIncrementTime.SecondsAsF - OffsetMoveIncrementTimeLag
    else
      LevelCommandParser.MoveIncrementTime.Ticks := 0;
    Result := 'level ' + LevelCommandParser.ParametersToString;
  finally
    LevelCommandParser.Free;
  end;
end;

function CorrectCommands(const ALine: string): string;
var
  Command: string;
  InLineIndex: SG;
begin
  InLineIndex := 1;
  Command := ReadToChar(ALine, InLineIndex, CharSpace);
  if Command = 'time' then
  begin
    Result := CorrectTimeCommand(ReadToNewLine(ALine, InLineIndex));
  end
  else if Command = 'level' then
  begin
    Result := CorrectLevelCommand(ReadToNewLine(ALine, InLineIndex));
  end
  else
    Result := ALine;
end;

end.
