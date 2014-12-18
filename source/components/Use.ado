cap pr drop Use
program define Use, rclass
syntax, index(string) [cond(string asis) ///
	group(string) grouplabel(string asis) ///
	header(string) headerlabel(string asis) ///
	sort(string) sortmerge(string) echo]
estimates clear
if (`"`cond'"'!="") local cond if `cond'

	qui use `cond' using "`index'", clear
	di as text ("(loading `c(N)' estimation results)")

	if ("`sortmerge'"!="" & "`sort'"!="") {
		rename depvar varname
		qui merge m:1 varname using "`sortmerge'", keep(master match) nogen nolabel nonotes keepusing("sort_depvar")
		rename varname depvar
	}

	if ("`group'"!="" | "`header'"!="") local sort `group' `header' __precedence__ `sort'

	if ("`group'"!="") {
		qui gen int __precedence__ = . // Lower values will be sorted first (aka to the left of the table)
		local i 0
		while (`"`grouplabel'"'!="") {
			gettoken s1 grouplabel : grouplabel
			gettoken s2 grouplabel : grouplabel
			qui replace __precedence__ = `++i' if `group'=="`s1'"
			qui replace `group' = "`s2'" if `group'=="`s1'"
		}
	}

	if ("`header'"!="") {
		cap qui gen int __precedence__ = . // Will do nothing if -group- is set
		replace __precedence__ =  100 * __precedence__
		local i 0
		while (`"`headerlabel'"'!="") {
			gettoken s1 headerlabel : headerlabel
			gettoken s2 headerlabel : headerlabel
			qui replace __precedence__ = `++i' if `header'=="`s1'"
			qui replace `header' = "`s2'" if `header'=="`s1'"
		}
	}

	if ("`sort'"!="") sort `sort'
	cap drop __precedence__

	conf str var __filename__
	keep __filename__

	forv i=1/`c(N)' {
		local fn = __filename__[`i']
		estimates use `fn'
		if ("`echo'"!="") noi di as text "[CMD]" _n as result `"`e(cmdline)'"' _n

		local indepvars : colnames e(b)
		local depvar `e(depvar)'
		local vars `depvar' `indepvars'
		local varlist : list varlist | vars
		local depvarlist `depvarlist' `depvar'
		local indepvarlist : list indepvarlist | indepvars
		local models `"`models' "`fn'""'

		estimates title: `fn'
		estimates store est`i', nocopy

	}
	
	local varcons _cons
	local varlist : list varlist - varcons
	local indepvarlist : list indepvarlist - varcons

	local numvars : list sizeof varlist
	local numdepvars : list sizeof depvarlist
	local numindepvars : list sizeof indepvarlist
	
	return scalar num_models = c(N)
	return scalar num_vars = `numvars'
	return scalar num_depvars = `numdepvars'
	return scalar num_indepvars = `numindepvars'

	return local varlist `varlist'
	return local depvarlist `depvarlist'
	return local indepvarlist `indepvarlist'
	return local models `"`models'"'
	clear
end
