* Replay regression
cap pr drop View
program define View, eclass
	local filename `0'
	estimates use "`filename'"
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

	/*
	local keys = e(keys)
	if ("`keys'"!="") {
		di as text _n "{title:Saved Notes}"
		foreach key of local keys {
			di as text " `key' = " as result "`e(`key')'"
		}
	}
	*/
end

