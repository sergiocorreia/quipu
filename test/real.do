pr drop _all
set more off
clear all
cls
adopath + "D:\Dropbox\Projects\stata\misc"
cd ../source

estdb setpath "D:\Dropbox\Projects\CreditCards\out\Regression"
local keys cmd subcmd vce vcetype depvar endogvars indepvars instruments absvars clustvar dofmethod N_hdfe




*tic
*estdb build, keys(`keys')
*toc, report
*estdb update
estdb use
estdb use if cmd!="reghdfe"

*estdb list if cmd=="reghdfe" & subcmd=="ivreg2" & depvar=="will_default24" & logfile=="Robustness_Simple"
*estdb br if cmd=="reghdfe" & subcmd=="ivreg2" & depvar=="will_default24" & logfile=="Robustness_Simple"

local cond cmd=="reghdfe" & subcmd=="ivreg2" & depvar=="will_default24" & logfile=="Robustness_Simple" & N_hdfe==5 & ubigeos=="" & smpl==.
local cond strpos(path, "individuals_debtors") & strpos(depvar, "will_") & model=="second" & subcmd=="ivreg2" & instruments=="entry_store_*"
*estdb tab if `cond' , plot
*estdb replay if `cond'
estdb table if `cond' , b(%3.2f)

*estdb export if `cond', as(tex) replace
*estdb export using tmp/borrar if `cond', as(tex) replace

tic
set trace off
estdb export using "tmp/bor rar" if `cond', replace as(pdf) ///
	latex_engine(xelatex) verbose(2) title("Some Title: With Weird % ! / a_b Signs") label("tex-label") view	
toc, report
exit

estdb desc if ..
li br table
report
 

 
