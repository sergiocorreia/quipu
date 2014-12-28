pr drop _all
set more off
clear all
cls
adopath + "D:\Dropbox\Projects\stata\misc"
estdb setpath "D:\Dropbox\Projects\CreditCards\out\Regression"
local keys cmd subcmd vce vcetype depvar endogvars indepvars instruments absvars clustvar dofmethod N_hdfe


set trace off
tic
estdb build, keys(`keys')
toc
* estdb update



exit

estdb desc if ..
li br table
report
 
