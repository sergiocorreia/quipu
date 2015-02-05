* (This is meant to be run WITHOUT quipu installed)
	cap ado uninstall quipu
	assert inlist(_rc, 0, 111)

* Prep work
	clear all
	cls
	set more off
	local repo "D:\Github\quipu"
	
	local path "`repo'\test\tmp"
	* Don't use `path' to avoid big bugs where I delete everything
	!del "`repo'\test\tmp\*.*" /q
	!del "`repo'\test\tmp\foo\*.*" /q
	cap mkdir "`path'" // git won't save empty folders
	
	*qui adopath + "`repo'\source"
	cd "`repo'\source"

* Set up quipu
* There is a REAL risk of keeping old/stale/wrong results in the quipu path (or a subfolder)
* To partially address this, when there are already .ster files, we force you to use -append-
* (to ignore possible problem), or -replace- (to delete .ster files)
	quipu setpath "`path'/foo" // , replace //  append // replace

* Run regressions and add results to db
	sysuse auto

	quipu save: reg price weight
	quipu save: reg weight price
	quipu save, notes(model=ols smpl=2 vars=all): reg price length
	quipu save, prefix("bar"): reg price head length
	local fn = e(filename)
	// note that the final path should be returned in a hidden e(filename)
	di as text "`fn'"
	assert "`fn'"!="."

* Add .ster as an extension and see if I can open it
	* quipu associate // will run as administrator
	* !`fn' // calls new instance of stata

* Build index
	quipu setpath "`path'"
	quipu index, keys(depvar model)
	quipu update_varlist

* View one result
	quipu view "D:\Github\quipu\test\tmp\foo\7826-6430-22915172.ster"

* Load an index
	cap quipu use if 0
	assert _rc==2000
	
	quipu use if depvar=="price"
	assert c(N)==3

* Describe many results
	*quipu describe if ..
	*quipu list if ..
	*quipu browse if ..
	*quipu table if ..
	quipu replay

exit
