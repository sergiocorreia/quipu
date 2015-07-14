capture program drop BuildRHS
program define BuildRHS
syntax, EXTension(string) [rename(string asis) drop(string asis)] ///
	[indicate(string asis)] // Don't add labels to indicate

	* NOTE: -estout- requires that after a rename, all the options MUST USE THE NEW NAME
	* i.e. if I rename(price Precio), then when calling -esttab- I need to include keep(Precio)
	* (and so oon for varlabels, order, etc.)

	local indepvars $indepvars
	local N : word count `indepvars'
	qui set obs `N'
	qui gen varname =""

	* Fill -varname- and merge to get variable labels
	forv i=1/`N' {
		gettoken indepvar indepvars : indepvars
		qui replace varname = "`indepvar'" in `i'
	}
	clonevar expanded_name = varname
	qui replace varname = substr(varname, strpos(varname, ".")+1, .) // bugbug (need to generalize to e.g. i.x#i.y#L.z)
	qui merge m:1 varname using "${quipu_path}/varlist", keep(master match) ///
		nogen nolabel nonotes keepusing(varlabel footnote sort_indepvar sort_depvar)
	gen stub = substr(expanded_name, 1, strpos(expanded_name, "."))
	qui replace varlabel = stub + varlabel if varlabel!=""
	drop varname stub
	rename expanded_name varname

	* Drop variables
	if (`"`drop'"'!="") {
		gen byte dropit = 0
		while (`"`drop'"'!="") {
			gettoken s1 drop : drop
			qui replace dropit = 1 if regexm(varname, "^`s1'$")
		}
		if ($quipu_verbose>0) {
			qui levelsof varname if dropit, local(rhsdrop) clean
			di as text "(dropping variables: " as result "`rhsdrop'" as text ")"
		}
		qui drop if dropit
		drop dropit
	}

	* Rename variables. Note: Can't use estout for simple renames b/c it messes up the varlabels
	if (`"`rename'"'!="") {
		qui gen original = varname
		while (`"`rename'"'!="") {
			gettoken s1 rename : rename
			gettoken s2 rename : rename
			assert_msg `"`s2'"'!="", msg("rename() must have an even number of strings")
			local ss2 `" "`s2'" "'
			if (strpos(`"`ss2'"', "[")>1) {
				forval i = 1/10 {
					local ss2 = subinstr(`"`ss2'"', "[`i']", `"" + regexs(`i') + ""', .)
				}
			}
			qui replace varname = `ss2' if regexm(varname, "^`s1'$")
		}
		gen byte renamed = original!=varname
		forv i=1/`c(N)' {
			local renamed = renamed[`i']
			if (`renamed') {
				local rhsrename `rhsrename' `=original[`i']' `=varname[`i']'
				if ($quipu_verbose>0) {
					local notice `"`notice' as text " `=original[`i']'" as result " `=varname[`i']'""'
				}
			}
		}

		if (`"`rhsrename'"'!="") {
			if ($quipu_verbose>0) di as text "(renaming variables:" `notice' as text ")"

			* We don't want the labels of a renamed variable (else, why did we rename it?)
			replace varlabel = "" if renamed
			replace footnote = "" if renamed

			* By renaming we can end up with multiple vars:
			* Remove conflicting footnotes (+-)
			*qui bys varname (footnote): replace footnote = "" if _N>1 & footnote[1]!=footnote[_N]

			* Remove duplicate varnames (prioritize nonrenamed vars)
			qui bys varname (renamed sort_depvar): drop if _n>1
		}

		drop original renamed
	}

	* Set varlabel option
	* BUGBUG, put lags later
	bys sort_indepvar: gen byte lag = real(regexs(1)) if regexm(varname, "^L([0-9]+)\.")
	qui replace lag = 0 if missing(lag)
	sort sort_indepvar // orders RHS, and ensures footnote daggers will be in order
	sort sort_indepvar lag
	drop lag

	gen byte is_indicate = 0
	while (`"`indicate'"'!="") {
		gettoken part indicate : indicate
		gettoken part_label part_pattern : part , parse("=")
		gettoken eqsign part_pattern : part_pattern , parse("=")
		
		* Need to allow "stub1* stub*" syntax like -estout-
		foreach pat of local part_pattern { 
			assert "`pat'"!=""
			replace is_indicate = 1 if strmatch(varname, "`pat'")
		}
	}

	forv i=1/`c(N)' {
		local varname = varname[`i']
		local footnote = footnote[`i']
		local varlabel = varlabel[`i']
		local is_indicate = is_indicate[`i']

		if (`is_indicate') continue

		* If both footnotes and varlabels have nothing, then we don't need to relabel the var!
		* This is critical if we have a regr. with 1000s of dummies
		if ("`varlabel'"!="" | "`footnote'"!="") {
			* We need *something* as varlabel, to put next to the footnote dagger
			if ("`varlabel'"=="") local varlabel `"`varname'"'
			AddFootnote, ext(`extension') footnote(`footnote')
			local varlabels `"`varlabels' `varname' `"`varlabel'`r(symbolcell)'"' "'
		}
		local order `order' `varname'
	}

	* Fill contents of keep (must be done after the renames are made)
	* Also after indicate
	qui levelsof varname if !is_indicate, local(rhskeep) clean

	* Groups +-+-
	* ...

	drop _all // BUGBUG: clear?
	*local varlabels varlabels(`varlabels' _cons Constant , end("" "") nolast)
	local varlabels `"`varlabels' _cons Constant , end("" "") nolast"'

	* Set global option
	assert_msg "`rhskeep'"!="", msg("No RHS variables kept!")
	global quipu_rhsoptions varlabels(`varlabels') order(`order') rename(`rhsrename')
	
	*keep(`rhskeep') // bugs with keep (messes with indicate, refcat, etc.)

end
