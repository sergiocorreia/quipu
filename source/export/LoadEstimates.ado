capture program drop LoadEstimates
program define LoadEstimates, eclass
syntax [anything(name=header equalok everything)] , ///
	[indicate(string)] ///  [Fmt(string asis)]
	[scalebaseline(real 1.0)] ///
	[keyvar(string)]

	assert `scalebaseline'>0

	* Load estimates in the order set by varlist.dta (wrt depvar)
	rename depvar varname
	qui merge m:1 varname using "${quipu_path}/varlist", keep(master match) keepusing(sort_depvar) nogen nolabel nonotes
	rename varname depvar
	assert "${indepvars}"=="" // bugbug drop

	* "#" will be ignored when sorting
	local exclude autonumeric
	local header : list header - exclude

	* Variables that we need to construct from the estimates
	qui ds
	local existing_variables = r(varlist)
	local newvars : list header - existing_variables
	foreach var of local newvars {
		qui gen `var' = ""
	}
	forv i=1/`c(N)' {
		
		local fn = path[`i'] +"/"+filename[`i']
		local num_estimate = num_estimate[`i']
		estimates use "`fn'", number(`num_estimate')

		foreach var of local newvars {
			qui replace `var' = "`e(`var')'" in `i'
		}
		estimates drop .
	}

	* Sort the dataset (columns of table will reflect that)
	local groups
	foreach var of local header {
		if ("`var'"!="depvar") qui gen byte sort_`var' = .
		cap yaml local cats=metadata.header.sort.`var'
		assert inlist(_rc, 0, 510)
		if (!_rc) {
			local i 0
			while (`"`cats'"'!="") {
				gettoken cat cats : cats
				local is_string = strpos("`: type `var''", "str")==1
				if (`is_string') {
					qui replace sort_`var' = `++i' if `var'=="`cat'"
				}
				else {
					qui replace sort_`var' = `++i' if `var'==`cat'
				}
			}
		}
		bys `groups' sort_`var' `var': gen byte _group_`var' = _n==1
		qui replace _group_`var' = sum(_group_`var')
		local groups `groups' _group_`var'
	}

	sort `groups' time
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
		local num_estimate = num_estimate[`i']
		estimates use "`fn'", number(`num_estimate')

		* Inject stuff into e()
		if ("`e(exexog_ct)'"!="" & "`e(endog_ct)'"!="") StockYogo // Load Stock Yogo crit values at 20%

		cap conf matrix e(summarize)
		if !c(rc) & "`e(baseline)'"=="" {
			tempname summarize
			matrix `summarize' = e(summarize)
			cap matrix `summarize' = `summarize'["mean", "`e(depvar)'"] // row -mean- may not exist
			if (!c(rc)) {
				ereturn scalar baseline = `summarize'[1,1] * `scalebaseline'
				if ("`keyvar'"!="") {
					tempname b
					matrix `b' = e(b)
					cap matrix `b' = `b'["`keyvar'",1] // Assume first value is the one I care about
					ereturn scalar ratio_baseline = `b'[1,1] / e(baseline) * `scalebaseline' * 100
				}
			}
		}
		
		estimates title: "`fn'"
		GetVars, indicate(`indicate') pos(`i') // This injects `indepvars' and creates/replaces variables
		local indepvarlist : list indepvarlist | indepvars
		estimates store quipu`i', nocopy
	}
	global indepvars `indepvarlist'
	global absorb
end

* Get -indepvars- and base names for absorbed variables
capture program drop GetVars
program define GetVars
syntax, pos(integer) [indicate(string)]
	
	local vars : colnames e(b)

	if ("`indicate'"=="") {
		* Remove omitted
		foreach var of local vars {
			local is_omitted = regexm("`var'", "o\.")
			if (!`is_omitted') {
				local includedvars `includedvars' `var'
			}
		}
		c_local indepvars `includedvars'
		exit
	}

	* Default (always check for these)
	if ("`e(cmd)'"=="xtreg" & "`e(model)'"=="fe") local absorbed `absorbed' `e(ivar)' // xtreg,fe
	if ("`e(absvar)'"!="") local absorbed `absorbed' `e(absvar)' // areg
	if ("`e(absvars)'"!="") local absorbed `absorbed' `e(absvars)' // reghdfe

	* Check for patterns (id_*) and factor variables (123bn.id)
	if ("`indicate'"!="_cons") {
		local all "_all"
		local match_all : list all in indicate

		* This weird loop creates locals -basepatterns- -fn- (which evals a fn!) and -dotted- (which is kinda unnecesary)
		local i 0
		foreach pat of local indicate {
			if (strpos("`pat'", "*") | strpos("`pat'", "?")) {
				local basepatterns `patterns' `pat'
				* Too bad if a var matches more than one pattern
				local fn `macval(fn)' + `++i' * strmatch("\`var'", "`pat'")
			}
			else {
				local dotted `dotted' `pat'
			}
		}

		* Store non-indicator vars in `indepvars' and the base vars of the indicator ones in `absorbed'
		foreach var of local vars {

			local is_omitted = regexm("`var'", "o\.")
			if (`is_omitted') continue

			local is_indicator 0
			local basevar `var'
			while (regexm("`basevar'", "^[0-9]+[bn]*\.")) {
				local is_indicator 1
				local basevar = regexr("`basevar'", "[0-9]+[bn]*\.", "i.")
			}

			* Only evaluate this fn when needed, b/c it's slow
			local pattern_pos 0
			if (!`is_indicator' & "`basepatterns'"!="") {
				local pattern_pos = `fn'
				assert `pattern_pos'>=0 & `pattern_pos'<.
			}

			if (`is_indicator' & `match_all') {
				if ("`basevar'"!="`lastbasevar'") local absorbed `absorbed' `basevar'
				local lastbasevar `basevar'
			}
			else if (`is_indicator' & `: list basevar in dotted') {
				if ("`basevar'"!="`lastbasevar'") local absorbed `absorbed' `basevar'
				local lastbasevar `basevar'
			}
			else if (`pattern_pos') {
				local basevar : word `pattern_pos' of `basepatterns'
				if ("`basevar'"!="`lastbasevar'") local absorbed `absorbed' `basevar'
				local lastbasevar `basevar'
			}
			else {
				local indepvars `indepvars' `var'
			}
		}
	}

	c_local indepvars `indepvars'

	local absorbed : list uniq absorbed
	foreach var of local absorbed {
		* Remove Dots Hashes Question marks and Stars
		local fixedvar `var'
		local fixedvar = subinstr(subinstr("`fixedvar'", "?","_QQ_", .), "*","_SS_", .) // Pattern
		local fixedvar = subinstr(subinstr("`fixedvar'", ".","_DD_", .), "#","_HH_", .) // Factor variables

		cap gen byte ABSORBED_`fixedvar' = 0
		if (!_rc) la var ABSORBED_`fixedvar' "`var'"
		qui replace ABSORBED_`fixedvar' = 1 in `pos'
	}
end

* Problem: need to load estimates to use this..
capture program drop StockYogo
program define StockYogo, eclass
	* BUG: Only works with up to 2 endogvars
	* Piggybacks on ivreg2 and estadd!
	tempname stats cv
	mata: s_cdsy("`stats'", 5) // 2=10% bias, 3=20% bias, ... 5=10% size  7=20^ size
	local k2 = e(exexog_ct)
	local nendog = e(endog_ct)
	scalar `cv' = `stats'[`k2', `nendog']
	ereturn scalar stock_yogo = `cv'
	*di e(stock_yogo)
end
