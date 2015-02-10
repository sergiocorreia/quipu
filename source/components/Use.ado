capture program drop Use
program define Use, rclass
	* Parse (including workaround that allows to use if <cond> with variables not in dataset)
	estimates clear
	syntax [anything(name=ifcond id="if condition" everything)]
	if (`"`ifcond'"'!="") {
		gettoken ifword ifcond : ifcond
		assert_msg "`ifword'"=="if", msg("condition needs to start with -if-") rc(101)
		local if "if`ifcond'"
	}
	local path $quipu_path
	assert_msg `"`path'"'!="",  msg("Path not set. Use -quipu setpath PATH- to set the global quipu_path") rc(101)
	
	qui use `if' using "`path'/index", clear
	assert_msg c(N), msg(`"condition <`if'> matched no results"') rc(2000)
	di as text "(`c(N)' estimation results loaded)"

	* Drop empty columns
	foreach var of varlist _all {
		cap qui cou if `var'!=.
		if (_rc==109) {
			qui cou if `var'!=""
		}
		if (r(N)==0) drop `var'
	}
end
