Windows Registry Editor Version 5.00

; Created with Default Programs Editor
; http://defaultprogramseditor.com/

; This associates .ster files (call it with -quipu associate-)
; Extension is .ado so it gets downloaded

; Create file association for .ster files
[HKEY_CLASSES_ROOT\.ster]
@="ster_auto_file"

; Edit Verb
[HKEY_CURRENT_USER\Software\Classes\ster_auto_file\shell\open\command]
@="\"REPLACETHIS\" quipu view \\\"%1\\\""

; Edit File Type Description
[HKEY_CURRENT_USER\Software\Classes\ster_auto_file]
@="Stata Estimates"
[HKEY_CURRENT_USER\Software\Classes\ster_auto_file]
"FriendlyTypeName"="Stata Estimates"
