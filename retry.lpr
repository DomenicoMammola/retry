// Retry is a super simple CLI utility to retry the execution of a command.
//
// This Source Code Form is subject to the terms of the GPLv3 License.
// If a copy of the GPLv3 was not distributed with this
// file, You can obtain one at https://www.gnu.org/licenses/gpl-3.0.en.html.
//
// This software is distributed without any warranty.
//
// @author Domenico Mammola (mimmo71@gmail.com - www.mammola.net)
program retry;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp,
  Process,
  mLog, mLogPublishers, mLazarusVersionInfo;

type
  TRetryApplicationOptions = record
    iteration : integer;
    waitSeconds : integer;
    command : string;
  end;

  { TRetryApplication }

  TRetryApplication = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;


var
  logger : TmLog;

{ TRetryApplication }

procedure TRetryApplication.DoRun;
var
  tmpOpt : String;
  tmpNum, i : integer;
  options : TRetryApplicationOptions;
  pubFile : TmFilePublisher;
  processStrings : TStringList;
  executable, outputString : String;
begin
  options.iteration:= 2;
  options.waitSeconds:=10;
  options.command:= '';

  if (ParamCount = 0) or HasOption('h', 'help') then
  begin
    WriteHelp;
    Terminate(0);
    Exit;
  end;

  if HasOption('i', 'iteration') then
  begin
    tmpOpt := GetOptionValue('i', 'iteration');
    if TryStrToInt(tmpOpt, tmpNum) then
      options.iteration:= tmpNum;
  end;

  if HasOption('w', 'wait') then
  begin
    tmpOpt := GetOptionValue('w', 'wait');
    if TryStrToInt(tmpOpt, tmpNum) then
      options.waitSeconds:= tmpNum;
  end;

  if HasOption('c', 'command') then
    options.command := GetOptionValue('c', 'command');

  if HasOption('f', 'logfile') then
  begin
    tmpOpt := GetOptionValue('f', 'logfile');
    if tmpOpt <> '' then
    begin
      pubFile := TmFilePublisher.Create;
      pubFile.FileName:= tmpOpt;
      pubFile.CycleEveryDay:= true;
      pubFile.KeepDays:= 5;
      pubFile.CurrentLevel:= mlInfo;
      logManager.AddPublisher(pubFile, true);
      pubFile.Active:= true;
    end;
  end;

  if options.command = '' then
  begin
    Writeln('No command is defined. Unable to run.');
    logger.Error('No command is defined. Unable to run.');
    Terminate(1);
    Exit;
  end;

  processStrings := TStringList.Create;
  try
    CommandToList(options.command, processStrings);
    executable:= processStrings.Strings[0];
    processStrings.Delete(0);

    for i := 1 to options.iteration do
    begin
      logger.Info(Format('Iteration #%d of %d', [i, options.iteration]));

      logger.Info('Start executing ' + options.command);

      if RunCommand(executable, processStrings.ToStringArray, outputString, [poNoConsole, poWaitOnExit, poStderrToOutPut]) then
      begin
        logger.info(Format('Successful after %d attempts', [i]));
        Terminate(0);
        Exit;
      end
      else
      begin
        logger.info(Format('Failed %d attempt: %s', [i, outputString]));
      end;

      logger.Info(Format('Sleeping for %d seconds', [options.waitSeconds]));
      Sleep(1000 * options.waitSeconds);
    end;
  finally
    processStrings.Free;
  end;

  // stop program loop
  logger.Info(Format('Failed all the %d attempts',[options.iteration]));
  Terminate(1);
end;

constructor TRetryApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  logger := logManager.AddLog('retry');
  StopOnException:=True;
end;

destructor TRetryApplication.Destroy;
begin
  inherited Destroy;
end;

procedure TRetryApplication.WriteHelp;
var
  s : String;
begin
  writeln('RETRY - Retry command execution until successful');
  writeln(Format('Version %s - https://github.com/DomenicoMammola/retry', [GetFileVersionAsString]));
  writeln('');
  s := ExtractFileName(ExeName);
  writeln('Usage: ', s, ' <parameters>');
  writeln('');
  writeln('Parameters:');
  writeln('-h, --help                prints help information');
  writeln('-i, --iteration <count>   max number of iteration (default 2)');
  writeln('-w, --wait <seconds>      waiting time between iterations in seconds (default 10)');
  writeln('-f, --logfile <log file>  log filename (will be added a timestamp string at the begin of the filename)');
  writeln('-c, --command <command>   command to be executed');
  writeln('');
  writeln('Examples:');
  writeln(s, ' -i 3 -w 10 -c my_command.exe');
  writeln(s, ' -i 3 -w 10 -c "my_command.exe param1 param2"');
  writeln(s, ' -f ".' + DirectorySeparator + '-my-log.txt" -c my_command.exe');
end;

var
  Application: TRetryApplication;

{$R *.res}

begin
  Application:=TRetryApplication.Create(nil);
  Application.Title:='retry';
  Application.Run;
  Application.Free;
end.

