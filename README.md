# retry
Retry is a super simple CLI utility to retry the execution of a command


```
Usage: retry.exe <parameters>

Parameters:
-h, --help                prints help information
-i, --iteration <count>   max number of iteration (default 2)
-w, --wait <seconds>      waiting time between iterations in seconds (default 10)
-f, --logfile <log file>  log filename (will be added a timestamp string at the begin of the filename)
-c, --command <command>   command to be executed

Examples:
retry.exe -i 3 -w 10 -c my_command.exe
retry.exe -i 3 -w 10 -c "my_command.exe param1 param2"
retry.exe -f ".\-my-log.txt" -c my_command.exe
```

This little free utility is licensed under the GNU GENERAL PUBLIC LICENSE v.3.



