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
end
