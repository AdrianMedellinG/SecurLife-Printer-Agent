Option Explicit

Dim shell
Dim fso
Dim scriptDir
Dim projectDir
Dim command
Dim logDir
Dim logPath
Dim logFile

Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
projectDir = fso.GetParentFolderName(scriptDir)
logDir = projectDir & "\tmp"
logPath = logDir & "\hidden-start.log"

If Not fso.FolderExists(logDir) Then
  fso.CreateFolder(logDir)
End If

command = "cmd.exe /d /s /c """"" & scriptDir & "\start-printer-agent.cmd"" """ & projectDir & """"""

Set logFile = fso.OpenTextFile(logPath, 8, True)
logFile.WriteLine Now & " - " & command
logFile.Close

shell.Run command, 0, False
