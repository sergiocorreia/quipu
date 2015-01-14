* Prep work	
	set more off
	clear all
	cls
	
	local repo "D:\Github\estdb"
	local path "`repo'\test\tmp"
	* Don't use `path' to avoid big bugs where I delete everything
	!del "`repo'\test\tmp\*.*" /q
	!del "`repo'\test\tmp\foo\*.*" /q
	cap mkdir "`path'" // git won't save empty folders
	qui adopath + "`repo'\source"
	cd "`repo'\source"

* Set up estdb
* There is a REAL risk of keeping old/stale/wrong results in the estdb path (or a subfolder)
* To partially address this, when there are already .ster files, we force you to use -append-
* (to ignore possible problem), or -replace- (to delete .ster files)
	estdb setpath "`path'/foo" // , replace //  append // replace
	
* Run regressions and add results to db
	sysuse auto
	estdb add, notes(test=1): areg price weight, a(turn)
	estdb add, notes(test=1): areg price weight, a(rep)
	estdb add, notes(test=1): reg price weight
	estdb add, notes(test=1): areg price length, a(rep)

	
* Build index
	estdb build_index, keys(depvar model absvar)

*		estdb use
*		asd
* Show table
set trace off
 	estdb export using `path'/table if test==1, as(pdf) verbose(2) view ///
		metadata(header.sort.absvar `"turn "" rep78"') ///
		header(cmd rank # absvar depvar) title(asd) label(foo) begin(_tab) ///
		stats(default F , l(N "Obs."))

exit
rmdir `path'
exit
