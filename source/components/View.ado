* Replay regression
cap pr drop View
program define View, eclass
	syntax anything(name=filename) , [N(integer 0)]
	local filename : subinstr local filename `"""' "", all
	
	qui estimates describe using "`filename'"
	local num_estimates = r(nestresults)
	assert `num_estimates'>0 & `num_estimates'<.

	* Quick hack to show just the selected estimate
	local start 1
	local end `num_estimates'
	if (`n'>0) {
		local start `n'
		local end `n'
	}

	if (`num_estimates'>1 & `n'==0) di as text "(showing `num_estimates' estimates)"

	forval i = `start'/`end' {
		estimates use "`filename'", number(`i')
		if "`e(keys)'"!="" {
			di as text "{title:Classification}"
			foreach key in `e(keys)' {
				local ans `ans' as text " `key'=" as result "`e(`key')'"
			}
			di `ans' _n
		}
		di as text "{title:Command}"
		di as input `"`e(cmdline)'"' _n

		if ("`e(estimates_title)'"!="") {
			di as text "{title:Title}"
			di as input `"`e(estimates_title)'"' _n			
		}

		di as text "{title:Estimation Results}"
		`e(cmd)' // -estimates replay- writes an unwanted title row
	}
end

