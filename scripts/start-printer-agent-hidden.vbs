Option Explicit

Dim shell
Dim fso
Dim scriptDir
Dim projectDir
Dim command

Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
projectDir = fso.GetParentFolderName(scriptDir)

command = "cmd.exe /d /c """ & scriptDir & "\start-printer-agent.cmd"" """ & projectDir & """"
shell.Run command, 0, False
