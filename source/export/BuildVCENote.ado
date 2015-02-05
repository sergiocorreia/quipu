capture program drop BuildVCENote
program define BuildVCENote
syntax, [vcenote(string)]
	if ("`vcenote'"=="") {
		qui levelsof vce, missing local(vce) clean
		if inlist("`vce'", "unadjusted") local vce "ols"
		if !inlist("`vce'", "ols", "robust", "cluster") {
			di as error "(cannot autogenerate vce note for vcetype <`vce'>, use -vcenote- option if you don't want it empty)"
		}
		else if ("`vce'"=="ols") {
			global quipu_vcenote "Standard errors in parentheses"
		}
		else if ("`vce'"=="robust") {
			global quipu_vcenote "Robust standard errors in parentheses"
		}
		else if ("`vce'"=="cluster") {
			qui levelsof clustvar, missing local(clustvar) clean
			local cond = `"inlist(varname, ""' + subinstr("`clustvar'", "#", `"", ""', .) + `"")"'
			qui use varname varlabel if `cond' using "${quipu_path}/varlist", clear
			qui replace varlabel = varname if missing(varlabel)
			forval i = 1/`c(N)' {
				local sep = cond(`i'==1, "", cond(`i'==c(N), " and ", ", "))
				local varlabel = varlabel[`i']
				local clustlabel `clustlabel'`sep'`varlabel'
			}
			global quipu_vcenote "Robust standard errors in parentheses, clustered by `clustlabel'."
		}
	}

	if "$quipu_vcenote"=="" {
		global quipu_vcenote "`vcenote'"
	}
	clear // Because we -use-d the dataset
end
