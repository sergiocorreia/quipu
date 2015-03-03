* Replay regression
cap pr drop View
program define View, eclass
	local filename `0'
	
	qui estimates describe using "`filename'"
	local num_estimates = r(nestresults)
	assert `num_estimates'>0 & `num_estimates'<.

	forval i = 1/`num_estimates' {
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
		di as text "{title:Estimation Results}"
		`e(cmd)' // -estimates replay- writes an unwanted title row
	}
end

