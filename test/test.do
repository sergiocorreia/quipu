* Prep work
	clear all
	cls
	set more off
	local repo "D:\Github\estdb"
	local path "`repo'\test\tmp"
	* Don't use `path' to avoid big bugs where I delete everything
	!del "`repo'\test\tmp\*.*" /q
	!del "`repo'\test\tmp\foo\*.*" /q
	cap mkdir "`path'" // git won't save empty folders
	qui adopath + "`repo'\source"

* Set up estdb
* There is a REAL risk of keeping old/stale/wrong results in the estdb path (or a subfolder)
* To partially address this, when there are already .ster files, we force you to use -append-
* (to ignore possible problem), or -replace- (to delete .ster files)
	estdb setpath "`path'/foo" // , replace //  append // replace

* Run regressions and add results to db
	sysuse auto

	reg price weight
	estdb add
	estdb add: reg weight price
	reg price length
	estdb add, notes(model=ols smpl=2 vars=all)

	reg price head length
	estdb add, prefix("bar")
	local fn = e(filename)
	// note that the final path should be returned in a hidden e(filename)
	di as text "`fn'"
	assert "`fn'"!="."

* Add .ster as an extension and see if I can open it
	* estdb associate // will run as administrator
	* !`fn' // calls new instance of stata

* Build index
	estdb setpath "`path'"
	estdb build_index, keys(depvar model)
	estdb update_varlist

* View one result
	estdb view "D:\Github\estdb\test\tmp\foo\7826-6430-22915172.ster"

* Load an index
	cap estdb use if 0
	assert _rc==2000
	
	estdb use if depvar=="price"
	assert c(N)==3

* Describe many results
	asd

	estdb describe if ..
	estdb list if ..
	estdb browse if ..
	estdb table if ..

* Show table
* Build latex table
	estdb report if .. , smcl|latex

rmdir `path'
exit
