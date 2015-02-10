* Prep work
	discard
	clear all
	cls
	set more off
	local repo "D:\Github\quipu"
	cd "`repo'\source"
	*qui adopath + "`repo'\source"
	quipu setpath "`repo'\test/tmp" // , append

	quipu tabulate // if ..
	*quipu list if ..
	*quipu browse if ..
	*quipu table if ..

* Build latex table
set trace off
set tracedepth 4
set traceexpand on
	quipu export if depvar=="price" using "`repo'\test\tmp.pdf" , verbose(2) ///
		view title("The Title \( \gamma^3 \)") label(tableurl) ///
		notes(Tenemos varios temas aca) header(depvar #)

	asd
	
exit
* TODO: Cleanup

PROBLEMA: Me sale que option filename es missing si using no esta! pero eso enreda
PROBLEMA: HACER Q VIEW NO SEA REQD


quipu export ... using "foobar.pdf"
quipu export ... using "foobar.tex"
quipu export ... using "foobar.html"


QUITAR AS Y USAR IMPLICITA LA EXTENSIONs
