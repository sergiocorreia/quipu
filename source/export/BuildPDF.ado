capture program drop BuildPDF
program define BuildPDF
syntax, filename(string) engine(string) [VIEW] [*]

	* PDF preface and epilogue
	qui findfile quipu-top.tex.ado
	local fn_top = r(fn)
	qui findfile quipu-bottom.tex.ado
	local fn_bottom = r(fn)


	* Substitute characters conflicting with latex
	local specialchars _ % $ // Latex special characters (don't substitute \ so we can insert math with \( \) )
	foreach char in `specialchars' {
		local substitute `substitute' `char' $BACKSLASH`char'
	}
	local substitute `substitute' "\_cons " Constant "..." "\ldots"

	local cmd esttab quipu* using "`filename'.tex"
	local tex_opt longtable booktabs substitute(`substitute')
	local pdf_options top(`fn_top') bottom(`fn_bottom')
	RunCMD `cmd', `tex_opt' `pdf_options' `options'

	local args engine(`engine') filename(`filename')
	cap erase "`filename'.log"
	cap erase "`filename'.aux"
	CompilePDF, `args'
	CompilePDF, `args' // longtable often requires a rerun
	di as text `"(output written to {stata "shell `filename'.pdf":`filename'.pdf})"'
	if ("`view'"!="") RunCMD shell `filename'.pdf
	cap erase "`filename'.log"
	cap erase "`filename'.aux"
end
