rebuild_git quipu

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
	qui adopath + "`repo'\source"

* Set up quipu
* There is a REAL risk of keeping old/stale/wrong results in the quipu path (or a subfolder)
* To partially address this, when there are already .ster files, we force you to use -append-
* (to ignore possible problem), or -replace- (to delete .ster files)
	quipu setpath "`path'/foo" // , replace //  append // replace

* Run regressions and add results to db
	sysuse auto
	bys turn: gen t = _n
	xtset turn t

	reg price weight
	quipu save
	quipu save: reg weight price
	reg price length
	quipu save, notes(model=ols smpl=2 vars=all)

	reg price head length
	quipu save, prefix("bar")
	return list, all
	
	quipu save: reg price L.weight L2.weight
	
	*local fn = e(filename)
	*// note that the final path should be returned in a hidden e(filename)
	*di as text "`fn'"
	*assert "`fn'"!="."

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
	*assert c(N)==3

* Describe many results
	quipu export if 1 using borrar.html,  view
	asd

	quipu describe if ..
	quipu list if ..
	quipu browse if ..
	quipu table if ..

* Show table
* Build latex table
	quipu report if .. , smcl|latex

rmdir `path'
exit
