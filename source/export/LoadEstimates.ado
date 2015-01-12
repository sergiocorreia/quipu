capture program drop LoadEstimates
program define LoadEstimates
	* Load estimates in the order set by varlist.dta (wrt depvar)
	rename depvar varname
	qui merge m:1 varname using "${estdb_path}/varlist", keep(master match) keepusing(sort_depvar) nogen nolabel nonotes
	sort sort_depvar
	drop sort_depvar varname
	assert "${indepvars}"==""

	forv i=1/`c(N)' {
		local fn = path[`i'] +"/"+filename[`i']
		estimates use "`fn'"
		estimates title: "`fn'"

		local indepvars : colnames e(b)
		local indepvarlist : list indepvarlist | indepvars

		estimates store estdb`i', nocopy
	}

	global indepvars `indepvarlist'
	clear
end
