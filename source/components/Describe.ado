cap pr drop Describe
program define Describe
syntax, index(string) [cond(string asis)] [noRESTORE]
	describe using `index', simple
	assert inlist("`restore'","", "norestore")

	if (`"`cond'"'!="") {
		if ("`restore'"=="") preserve
		di
		use if `cond' using `index', clear

		di as text "List of saved estimates:"
		forv i=1/`c(N)' {
			local fn = __filename__[`i']
			gettoken left right : fn, parse(":")
			gettoken colon right : right, parse(":")

			if ("`right'"!="") {
				di as text `"{stata estmgr view "`left'\`=char(58)'`right'" : `fn' } "'
			}
			else {
				di as text `"{stata estmgr view "`fn'" : `fn' } "'
			}
		}
		drop __*
		if (c(N)==0) exit
		foreach var of varlist _all {
			qui levelsof `var'
			local n : word count `r(levels)'
			if (`n'>1) tab `var', m sort
		} 
		if ("`restore'"=="") restore
	}

end
