capture program drop BuildTEX
program define BuildTEX
syntax, filename(string) [*]

	* Substitute characters conflicting with latex
	local specialchars _ % $ // Latex special characters (don't substitute \ so we can insert math with \( \) )
	foreach char in `specialchars' {
		local substitute `substitute' `char' $BACKSLASH`char'
	}
	local substitute `substitute' "\_cons " Constant
	local cmd esttab estdb* using "`filename'.tex"
	local tex_opt longtable booktabs substitute(`substitute')
	RunCMD `cmd', `tex_opt' `options'
end
