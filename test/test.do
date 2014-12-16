* Prep work
	clear all
	cls
	set more off
	local repo "D:\Github\estdb"
	local path "`repo'\test\tmp"
	cap mkdir "`path'" // git won't save empty folders
	qui adopath + "`repo'\source"

* Set up estdb
* There is a REAL risk of keeping old/stale/wrong results in the estdb path (or a subfolder)
* To partially address this, when there are already .ster files, we force you to use -append-
* (to ignore possible problem), or -replace- (to delete .ster files)
	estdb setpath "`path'/foo" , replace //  append // replace

* Run regressions and add results to db
	sysuse auto

	reg price weight
	estdb add
	estdb add: reg weight price
	reg price length
	estdb add, notes(model=2)

	reg price head length
	estdb add, prefix("bar")
	local fn = e(filename)
	// note that the final path should be returned in a hidden e(filename)
	di as text "`fn'"
	assert "`fn'"!="."

* Add .ster as an extension and see if I can open it
	estdb associate // will run as administrator
	!`fn'

	asd

* Build index
	estdb build_index, keys(depvar model)

* View one result

* Describe many results

* Show table

* Build latex table


rmdir `path'
exit
