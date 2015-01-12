capture program drop LoadEstimates
program define LoadEstimates
	syntax, header(string)

	* Load estimates in the order set by varlist.dta (wrt depvar)
	rename depvar varname
	qui merge m:1 varname using "${estdb_path}/varlist", keep(master match) keepusing(sort_depvar) nogen nolabel nonotes
	rename varname depvar
	assert "${indepvars}"==""

	* BUGBUG
	SetMetadata header.sort.absvar = turn "" rep78

	* Load the variables with the table headers
	qui ds
	local existing_variables = r(varlist)
	local special_headers depvar #
	local header_vars : list header - special_headers
	local header_newvars : list header_vars - existing_variables

	if (`: list posof "depvar" in header'==0) drop depvar
	
	foreach var of local header {
		cap gen `var' = ""
		cap GetMetadata sort_`var'=header.sort.`var'
		assert inlist(_rc, 0, 510)
		if !_rc {
			cap gen byte _sort_`var'_ = .
			local header_sortvars `header_sortvars' `var'
		}
	}
	
	forv i=1/`c(N)' {
		local fn = path[`i'] +"/"+filename[`i']
		estimates use "`fn'"
		estimates title: "`fn'"

		local indepvars : colnames e(b)
		local indepvarlist : list indepvarlist | indepvars

		foreach var of local header_newvars {
			qui replace `var' = "`e(`var')'" in `i'
		}

		estimates store estdb_tmp`i', nocopy
	}

	* Fill the _sort_`var'_ variables
	gen byte _index_ = _n
	foreach var of local header_vars {
		if (`: list var in header_sortvars') {
			local i 0
			local cats `sort_`var''
			assert "`cats'"!=""
			while ("`cats'"!="") {
				gettoken cat cats : cats
				cap replace _sort_`var'_ = `++i' if (_sort_`var'_==.) & (`var'=="`cat'")
				if (_rc==109) /* type mismatch */ qui replace _sort_`var'_ = `i' if (_sort_`var'_==.) & (`var'==`cat')
			}
			local sort `sort' _sort_`var'_			
		}
		else {
			local sort `sort' `var'
		}
	}
	local sort `sort' sort_depvar
	sort `sort'

	* Sort -estimates-
	forv i=1/`c(N)' {
		local j = _index_[`i']
		qui estimates restore estdb_tmp`j'
		estimates store estdb`i', nocopy
	}
	estimates drop estdb_tmp*
	asd
	drop sort_depvar _sort_*_ _index_

	* TODO
	* add labels for the header groups

	global indepvars `indepvarlist'
end
