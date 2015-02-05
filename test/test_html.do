* Prep work
	clear all
	cls
	set more off
	local repo "D:\Github\estdb"
	cd "`repo'\source"
	*qui adopath + "`repo'\source"
	estdb setpath "`repo'\test/tmp" // , append

	estdb tabulate // if ..
	*estdb list if ..
	*estdb browse if ..
	*estdb table if ..

* Build latex table
	estdb export if depvar=="price" using "`repo'\test\tmp" , as(tex pdf) replace view

exit
* TODO: Cleanup

PROBLEMA: Me sale que option filename es missing si using no esta! pero eso enreda
PROBLEMA: HACER Q VIEW NO SEA REQD


estdb export ... using "foobar.pdf"
estdb export ... using "foobar.tex"
estdb export ... using "foobar.html"


QUITAR AS Y USAR IMPLICITA LA EXTENSIONs
