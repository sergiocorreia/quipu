pr drop _all
set more off
clear all
cls

estdb setpath "D:\Dropbox\Projects\CreditCards\out\Regression"
local keys cmd subcmd vce vcetype depvar endogvars indepvars instruments absvars clustvar dofmethod N_hdfe

set trace off
estdb build, keys(`keys')
* estdb update



exit

estdb desc if ..
li br table
report
 