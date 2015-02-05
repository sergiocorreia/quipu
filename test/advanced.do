* Prep work	
	set more off
	clear all
	cls
	
	local repo "D:\Github\quipu"
	local path "`repo'\test\tmp"
	* Don't use `path' to avoid big bugs where I delete everything
	!del "`repo'\test\tmp\*.*" /q
	!del "`repo'\test\tmp\foo\*.*" /q
	cap mkdir "`path'" // git won't save empty folders
	qui adopath + "`repo'\source"
	cd "`repo'\source"

* Set up quipu
* There is a REAL risk of keeping old/stale/wrong results in the quipu path (or a subfolder)
* To partially address this, when there are already .ster files, we force you to use -append-
* (to ignore possible problem), or -replace- (to delete .ster files)
	quipu setpath "`path'/foo" // , replace //  append // replace
	
* Run regressions and add results to db
	sysuse auto
	quipu save, notes(test=1): areg price weight, a(turn)
	quipu save, notes(test=1): areg price weight, a(rep)
	quipu save, notes(test=1): reg price weight
	quipu save, notes(test=1): areg price length, a(rep)

	
* Build index
	quipu index, keys(depvar model absvar)

*		quipu use
*		asd
* Show table
set trace off
 	quipu export using `path'/table if test==1, as(pdf) verbose(2) view ///
		metadata(header.sort.absvar `"turn "" rep78"') ///
		header(cmd rank # absvar depvar) title(asd) label(foo) begin(_tab) ///
		stats(default F , l(N "Obs."))

exit
rmdir `path'
exit
