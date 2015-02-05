capture program drop LoadEstimates
program define LoadEstimates
syntax [anything(name=header equalok everything)] [ , Fmt(string asis)]

	* Load estimates in the order set by varlist.dta (wrt depvar)
	rename depvar varname
	qui merge m:1 varname using "${quipu_path}/varlist", keep(master match) keepusing(sort_depvar) nogen nolabel nonotes
	rename varname depvar
	assert "${indepvars}"=="" // bugbug drop

	* "#" will be ignored when sorting
	local autonumeric #
	local header : list header - autonumeric

	* Variables that we need to construct from the estimates
	qui ds
	local existing_variables = r(varlist)
	local newvars : list header - existing_variables
	foreach var of local newvars {
		qui gen `var' = ""
	}
	forv i=1/`c(N)' {
		local fn = path[`i'] +"/"+filename[`i']
		estimates use "`fn'"
		foreach var of local newvars {
			qui replace `var' = "`e(`var')'" in `i'
		}
		estimates drop .
	}

	* Sort the dataset (columns of table will reflect that)
	local groups
	foreach var of local header {
		if ("`var'"!="depvar") qui gen byte sort_`var' = .
		cap GetMetadata cats=header.sort.`var'
		assert inlist(_rc, 0, 510)
		if (!_rc) {
			local i 0
			while ("`cats'"!="") {
				gettoken cat cats : cats
				qui replace sort_`var' = `++i' if "`var'"=="`cat'"
			}
		}

		bys `groups' sort_`var' `var': gen byte _group_`var' = _n==1
		qui replace _group_`var' = sum(_group_`var')
		local groups `groups' _group_`var'
	}

	sort `groups'
	gen byte _index_ = _n

	foreach var of local header {
		bys _group_`var': gen byte span_`var' = _N
		bys _group_`var' (_index_): gen byte inactive_`var' = _n>1
		order `var' sort_`var' span_`var' inactive_`var', last
	}

	sort `groups' // Redundant
	drop _group_*

	* Load estimates
	forv i=1/`c(N)' {
		local fn = path[`i'] +"/"+filename[`i']
		estimates use "`fn'"
		estimates title: "`fn'"
		local indepvars : colnames e(b)
		local indepvarlist : list indepvarlist | indepvars
		estimates store quipu`i', nocopy
	}
	global indepvars `indepvarlist'
end
