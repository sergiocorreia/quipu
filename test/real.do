pr drop _all
set more off
clear all
cls
adopath + "D:\Dropbox\Projects\stata\misc"
cd ../source

estdb setpath "D:\Dropbox\Projects\CreditCards\out\Regression"
local keys cmd subcmd vce vcetype depvar endogvars indepvars instruments absvars dofmethod N_hdfe

/*
tic
* Create index
	estdb build, keys(`keys')

* Quick and dirty (maybe allow a program to run at the end of -build- to generate all this?)
	use "${estdb_path}/index"
	gen definition = regexs(1) if regexm(depvar, "will_(default|late)([0-9]+)")
	gen byte horizon = real(regexs(2)) if regexm(depvar, "will_(default|late)([0-9]+)")
	save, replace
toc, report
*/

estdb update

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
set trace on
set tracedepth 3
estdb export using "../test/tmp/bor rar" if `cond', replace as(pdf) ///
	latex_engine(xelatex) verbose(2) title("Some Title: With Weird % ! / a_b Signs") label("tex-label") view ///
	drop(sunat.*) rename(S_num_branch.* "spam" "new.*rel" "foo") header(definition horizon #, fmt(horizon "@ months")) ///
	orientation(landscape) size(5) pagebreak cellformat(b(a1) se(a1)) /// stats(r2 N)
	
	
toc, report
exit

estdb desc if ..
li br table
report
 

 

exit

* Example of super-advanced syntax for estdb export

estdb export using FILENAME if CONDITION , REPLACE as(pdf) latex(xelatex) verbose(2) title(SOMETITLE) label(SOMELABEL) view ///
	footnotes(spam "Something something" eggs "Else else" ... potentially HUGE strings here) /// MEJOR: footnotedict(OBJECT_NAME)
	notes(All the notes at the end (on top of VCE, etc)) ///
	stats(..) statsformats(..) ///
	group(..) grouplabel(..) groupnote(..) ///
	regexrename(..) regexdrop(..) nonumbers cellformat(..) se(..) 
	
En markdown hacer
 - prefix: estdb.doh
 - notes: ..
 
y en el dofile hacer include prefix


	
* The thing about footnotes is that I don't know which ones will I need ex ante..b etter to just give a dict or file!	
 
