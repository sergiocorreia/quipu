capture program drop ExportInner
program define ExportInner
syntax, filename(string) latex_engine(string) [html tex pdf] [*]


	if ($estdb_verbose>1) local noisily noisily 

	local using = cond("`filename'"=="","", `"using "`filename'.tex""')
	local base_cmd esttab estdb* `using' , `noisily'
	local base_opt varlabels(\`rhslabels') order(`rhsorder') mlabels(none) nonumbers
	local tex_opt longtable booktabs ///
		prehead(\`prehead') posthead(\`posthead') prefoot(\`prefoot') postfoot(\`postfoot') substitute(\`substitute')

	* Substitute characters conflicting with latex
	local specialchars _ % $ // Latex special characters (don't substitute \ so we can insert math with \( \) )
	foreach char in `specialchars' {
		local substitute `substitute' `char' $BACKSLASH`char'
	}
	local substitute `substitute' "\_cons " \_cons

	* Format LHS Variables

	* Format RHS Variables
	ProcessRHS, rename(`rename') drop(`drop') // returns r(rhslabels) -> varlabels and r(rhsorder) -> order
	local rhslabels `"`r(rhslabels)'"'
	local rhsorder `"`r(rhsorder)'"'
	local rhsdrop `"`r(rhsdrop)'"'
	local rhsrename `"`r(rhsrename)'"'
	if ("`rhsdrop'"!="") local base_opt `base_opt' drop(`rhsdrop')
	if ("`rhsrename'"!="") {
		local base_opt rename(`rhsrename') `base_opt'
	}

	* Prepare text/code surrounding the table (run AFTER all footnotes have been added)
	Prehead, colformat(`"`colformat'"') label(`"`label'"') title(`"`title'"')
	local prehead `"`r(prehead)'"'

	local line_subgroup // What was this?
	local posthead ${estdb_header}
	*`line_subgroup'\midrule
	local prefoot \midrule
	local postfoot \bottomrule ///
$ENTER\end{longtable} ///
$ENTER\end{ThreePartTable}

	* Save PDF
	if ("`pdf'"!="") {
		qui findfile estdb-top.tex.ado
		local fn_top = r(fn)
		qui findfile estdb-bottom.tex.ado
		local fn_bottom = r(fn)
		local pdf_options top(`fn_top') bottom(`fn_bottom')
		RunCMD `base_cmd' `base_opt' `tex_opt' `pdf_options' `options'

		* Compile
		if ("`filename'"!="") {
			local args latex_engine(`latex_engine') filename(`filename')
			cap erase "`filename'.log"
			cap erase "`filename'.aux"
			CompilePDF, `args'
			CompilePDF, `args' // longtable often requires a rerun
			di as text `"(output written to {stata "shell `filename'.pdf":`filename'.pdf})"'
			if ("`view'"!="") RunCMD shell `filename'.pdf
			cap erase "`filename'.log"
			cap erase "`filename'.aux"
		}
	}

	* Save TEX (after .pdf so it overwrites the interim tex file there)
	if ("`tex'"!="") {
		RunCMD `base_cmd' `base_opt' `tex_opt' `pdf_options' `options'
	}
end
