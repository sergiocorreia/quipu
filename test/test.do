* Prep work
	clear all
	cls
	local repo "D:\Github\estdb"
	local path "`repo'\test\tmp"
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
	estdb add, prefix("foo/bar_")
	local fn = e(filename)
	// note that the final path should be returned in a hidden e(filename)

* Add .ster as an extension and see if I can open it
	estdb associate // will run as administrator
	!`fn'


* Build index
	estdb build_index, keys(depvar model)

* View one result

* Describe many results

* Show table

* Build latex table


rmdir `path'
exit
