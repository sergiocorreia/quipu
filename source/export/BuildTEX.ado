capture program drop BuildTEX
program define BuildTEX
syntax, filename(string) [*]

	* Substitute characters conflicting with latex
	local specialchars _ % $ // Latex special characters (don't substitute \ so we can insert math with \( \) )
	foreach char in `specialchars' {
		local substitute `substitute' `char' $BACKSLASH`char'
	}
	local substitute `substitute' "\_cons " Constant

	if ($estdb_verbose>1) local noisily noisily
	local prepost prehead($estdb_prehead) posthead($estdb_header) prefoot($estdb_prefoot) postfoot($estdb_postfoot)
	local base_cmd esttab estdb* using "`filename'.tex"
	local base_opt `noisily' $estdb_rhsoptions `prepost' mlabels(none) nonumbers
	local tex_opt longtable booktabs substitute(`substitute')

	RunCMD `base_cmd' , `base_opt' `tex_opt' `options'
end
