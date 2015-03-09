cap pr drop Tabulate
program define Tabulate
syntax [anything(everything)] , [noLIst] [*]
	qui Use `anything'
	
	di as text _n "{bf:List of keys:}"
	de, simple
	if (c(N)==0) exit

	if ("`list'"!="nolist") {
		sort path filename num_estimate
		local last_fn
		di as text _n "{bf:List of saved estimates:}"
		forv i=1/`c(N)' {
			local fn = path[`i'] +"/"+filename[`i']
			local num_estimate = num_estimate[`i']
			di %3.0f `i' _c
			if ("`last_fn'"!="`fn'") di as text `"{stata "quipu view `fn', n(`num_estimate')" : `fn' } "'
			local last_fn "`fn'"
		}
	}

	drop path filename time
	di as text _n "{bf:Tabulates of keys that vary across estimates:}"
	foreach var of varlist _all {
		qui levelsof `var'
		local n : word count `r(levels)'
		if (`n'>1) tab `var', m sort `options'
	} 
end

/*
syntax, index(string) [cond(string asis)] [noRESTORE]
	Tabulate using `index', simple
	assert inlist("`restore'","", "norestore")

	if (`"`cond'"'!="") {
		if ("`restore'"=="") preserve
		di
		use if `cond' using `index', clear

		gettoken left right : fn, parse(":")
		gettoken colon right : right, parse(":")

		if ("`right'"!="") {
			di as text `"{stata estmgr view "`left'\`=char(58)'`right'" : `fn' } "'
		}
		else {
			di as text `"{stata estmgr view "`fn'" : `fn' } "'
		}
		}
*/
