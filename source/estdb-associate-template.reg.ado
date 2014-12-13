Windows Registry Editor Version 5.00

; Created with Default Programs Editor
; http://defaultprogramseditor.com/

; This associates .ster files (call it with -estdb associate-)
; Ado extension so it gets downloaded

; Edit Verb
[HKEY_CURRENT_USER\Software\Classes\ster_auto_file\shell\open\command]
@="\"REPLACETHIS\" estdb view \\\"%1\\\""

; Edit File Type Description
[HKEY_CURRENT_USER\Software\Classes\ster_auto_file]
@="Stata Estimates"
[HKEY_CURRENT_USER\Software\Classes\ster_auto_file]
"FriendlyTypeName"="Stata Estimates"
