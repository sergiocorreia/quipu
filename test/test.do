* Prep work
	clear all
	cls
	local path "D:\Github\estdb\test\tmp"
	adopath + "D:\Github\estdb\source"

* There is a REAL risk of keeping old/stale/wrong results in the estdb path (or a subfolder)
	estdb setpath "`path'/foo" , replace
	cap rmdir `path'
	mkdir `path'

	estdb init "`path'" // checks folder is empty

* Set up estdb
	

* Run regressions and add results to db
	sysuse auto

	reg price weight
	estdb add

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
