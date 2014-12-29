pr drop _all
set more off
clear all
cls
adopath + "D:\Dropbox\Projects\stata\misc"
cd ../source

estdb setpath "D:\Dropbox\Projects\CreditCards\out\Regression"
local keys cmd subcmd vce vcetype depvar endogvars indepvars instruments absvars clustvar dofmethod N_hdfe



set trace off
*tic
*estdb build, keys(`keys')
*toc, report
*estdb update

estdb use
estdb use if cmd!="reghdfe"

*estdb list if cmd=="reghdfe" & subcmd=="ivreg2" & depvar=="will_default24" & logfile=="Robustness_Simple"
*estdb br if cmd=="reghdfe" & subcmd=="ivreg2" & depvar=="will_default24" & logfile=="Robustness_Simple"

local cond cmd=="reghdfe" & subcmd=="ivreg2" & depvar=="will_default24" & logfile=="Robustness_Simple" & N_hdfe==5 & ubigeos=="" & smpl==.
*estdb tab if `cond' , plot
*estdb replay if `cond'
estdb table if `cond' , b(%3.2f)

estdb report if `cond'

exit

estdb desc if ..
li br table
report
 
