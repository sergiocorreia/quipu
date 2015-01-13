capture program drop BuildPDF
program define BuildPDF
syntax, filename(string) latex_engine(string) VIEW [*]

	* PDF preface and epilogue
	qui findfile estdb-top.tex.ado
	local fn_top = r(fn)
	qui findfile estdb-bottom.tex.ado
	local fn_bottom = r(fn)


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
	local pdf_options top(`fn_top') bottom(`fn_bottom')

	RunCMD `base_cmd' , `base_opt' `tex_opt' `pdf_options' `options'

	local args latex_engine(`latex_engine') filename(`filename')
	cap erase "`filename'.log"
	cap erase "`filename'.aux"
	CompilePDF, `args'
	CompilePDF, `args' // longtable often requires a rerun
	di as text `"(output written to {stata "shell `filename'.pdf":`filename'.pdf})"'
	if ("`view'"!="") RunCMD shell `filename'.pdf
	cap erase "`filename'.log"
	cap erase "`filename'.aux"
end
