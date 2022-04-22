param ($serverName, $databaseName, $username, $password, $scriptFilePath)

Invoke-Sqlcmd -ServerInstance "$(serverName)" -Database "$(databaseName)" -Username "$(username)" -Password "$(password)" -InputFile "$(scriptFilePath)" -QueryTimeout 36000 -Verbose
