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
  Process;

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

{ TRetryApplication }

procedure TRetryApplication.DoRun;
var
  tmpOpt : String;
  tmpNum, i, exitCode : integer;
  options : TRetryApplicationOptions;
  pr : TProcess;
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


  if options.command = '' then
  begin
    Writeln('No command is defined. Unable to run.');
    Terminate(1);
    Exit;
  end;

  for i := 1 to options.iteration do
  begin
    pr := TProcess.Create(nil);
    try
      // yes, it's deprecated but it implements a smart "ConvertCommandLine" procedure that I don't want to replicate here
      // as however I don't know which kind of command string would be used.. so avoid code replication!
      pr.CommandLine:= options.command;
      pr.Execute;
      exitCode:= pr.ExitStatus;
    finally
      pr.Free;
    end;

    if exitCode = 0 then
    begin
      Terminate(0);
      Exit;
    end;

    Sleep(1000 * options.waitSeconds);
  end;

  // stop program loop
  Terminate(1);
end;

constructor TRetryApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
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
  writeln('');
  s := ExtractFileName(ExeName);
  writeln('Usage: ', s, ' <parameters>');
  writeln('');
  writeln('Parameters:');
  writeln('-h, --help                prints help information');
  writeln('-i, --iteration <count>   max number of iteration (default 2)');
  writeln('-w, --wait <seconds>      waiting time between iterations in seconds (default 10)');
  writeln('-c, --command <command>   command to be executed');
  writeln('');
  writeln('Examples:');
  writeln(s, ' -i 3 -w 10 -c my_command.exe');
  writeln(s, ' -i 3 -w 10 -c "my_command.exe param1 param2"');
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

