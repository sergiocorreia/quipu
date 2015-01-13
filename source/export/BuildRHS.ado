capture program drop BuildRHS
program define BuildRHS
syntax, [rename(string asis) drop(string asis)]

	local indepvars $indepvars
	local N : word count `indepvars'
	qui set obs `N'
	qui gen varname =""

	* Fill -varname- and merge to get variable labels
	forv i=1/`N' {
		gettoken indepvar indepvars : indepvars
		qui replace varname = "`indepvar'" in `i'
	}
	qui merge m:1 varname using "${estdb_path}/varlist", keep(master match) nogen nolabel nonotes ///
		keepusing(varlabel footnote sort_indepvar sort_depvar)

	* Drop variables
	if (`"`drop'"'!="") {
		gen byte dropit = 0
		while (`"`drop'"'!="") {
			gettoken s1 drop : drop
			qui replace dropit = 1 if regexm(varname, "^`s1'$")
		}
		qui levelsof varname if dropit, local(rhsdrop) clean
		if ($estdb_verbose>0) di as text "(dropping variables: " as result "`rhsdrop'" as text ")"
		qui drop if dropit
		drop dropit
	}

	* Rename variables
	* Note: Can't use estout for simple renames b/c it messes up the varlabels
		* TODO (PERO DEMASIADO ENREDADO): permitir usar regexs()..
		* basicamente, hacer primero una pasada con regexm, luego aplicar regexr que permita sumar regexs(1)
	if (`"`rename'"'!="") {
		qui gen original = varname
		while (`"`rename'"'!="") {
			gettoken s1 rename : rename
			gettoken s2 rename : rename
			assert_msg `"`s2'"'!="", msg("rename() must have an even number of strings")
			qui replace varname = regexr(varname, "^`s1'$", "`s2'")
		}
		gen byte renamed = original!=varname
		forv i=1/`c(N)' {
			local renamed = renamed[`i']
			if (`renamed') {
				local rhsrename `rhsrename' `=original[`i']' `=varname[`i']'
				if ($estdb_verbose>0) {
					local notice `"`notice' as text " `=original[`i']'" as result " `=varname[`i']'""'
				}
			}
		}

		if (`"`rhsrename'"'!="") {
			if ($estdb_verbose>0) di as text "(renaming variables:" `notice' as text ")"

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

	* Groups +-+-
	* ...

	* Set varlabel option
	sort sort_indepvar // orders RHS, and ensures footnote daggers will be in order
	forv i=1/`N' {
		local varname = varname[`i']
		local varlabel = cond(varlabel[`i']=="", "`varname'", varlabel[`i'])
		local footnote = footnote[`i']
		local order `order' `varname'
		AddFootnote `footnote'
		local varlabels `"`varlabels' `varname' "`varlabel'`r(symbolcell)'" "'
	}

	drop _all // BUGBUG: clear?
	*local varlabels varlabels(`varlabels' _cons Constant , end("" "") nolast)
	local varlabels `"`varlabels' _cons Constant , end("" "") nolast"'

	* Set global option
	global estdb_rhsoptions varlabels(`varlabels') order(`order') rename(`rhsrename') drop(`rhsdrop')
end
