capture program drop BuildTEX
program define BuildTEX
syntax, filename(string) [*]

	* Substitute characters conflicting with latex
	local specialchars _ % $ // Latex special characters (don't substitute \ so we can insert math with \( \) )
	foreach char in `specialchars' {
		local substitute `substitute' `char' $BACKSLASH`char'
	}
	local substitute `substitute' "\_cons " Constant "..." "\ldots" "#" "\#"
	local cmd esttab quipu* using "`filename'.tex"
	local tex_opt longtable booktabs substitute(`substitute') modelwidth(1)
	* modelwdith(1) just makes the .tex smaller / easier to read
	RunCMD `cmd', `tex_opt' `options'
end
