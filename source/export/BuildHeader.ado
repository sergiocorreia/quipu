capture program drop BuildHeader
program define BuildHeader
syntax [anything(name=header equalok everything)] [ , EXTension(string) Fmt(string asis)]

	* Set replacement locals
	local header : subinstr local header "#" "autonumeric", word
	foreach cat of local header {
		if ("`cat'"=="autonumeric") {
			local template_`cat' "(@)"
		}
		else {
			local template_`cat' "@"
		}
	}
	while ("`fmt'"!="") {
		gettoken cat fmt : fmt
		gettoken template fmt : fmt
		local template_`cat' "`template'"
	}

	rename depvar varname
	qui merge m:1 varname using "${quipu_path}/varlist", keep(master match) nogen nolabel nonotes ///
		 keepusing(varlabel footnote)
	sort _index_ // rearrange
	rename varname depvar
	qui replace varlabel = depvar if missing(varlabel)

	if ("`extension'"=="html") {
		local cell_start `"$TAB$TAB<th colspan="\`n'">"'
		local cell_end "$TAB$TAB</th>"
		local cell_sep "${ENTER}"
		local cell_line // "\cmidrule(lr){\`start_col'-\`end_col'} "
		local row_start "${TAB}<tr>"
		local row_end "${TAB}</tr>"
		local row_sep ""
		local header_start "<thead>"
		local header_end "</thead>"
		local offset 1 // First cell in row is usually empty
		local topleft "$TAB$TAB<th></th>$ENTER"
		local topleft_auto `"`topleft'"'
	}
	else {
		local cell_start "\multicolumn{\`n'}{c}{"
		local cell_end "}"
		local cell_sep " & "
		local cell_line "\cmidrule(lr){\`start_col'-\`end_col'} "
		local row_start "${TAB}"
		local row_end "$TAB${BACKSLASH}${BACKSLASH}${ENTER}"
		local row_sep ""
		local header_start ""
		local header_end "$TAB\midrule"
		local offset 1 // First cell in row is usually empty
		local topleft "\multicolumn{1}{l}{} & "
		local topleft_auto "\multicolumn{1}{c}{} & "
	}

	local ans "`header_start'" // Will contain the header string
	local numrow 0
	foreach cat of local header {
		local ++numrow
		local line "$TAB"
		local numcell 0
		if ("`cat'"=="autonumeric") {
			local row "`row_start'`topleft_auto'"
			forval i = 1/`c(N)' {
				local cell = subinstr("`template_`cat''", "@", "`i'", .)
				local n 1
				local sep = cond(`i'>1, "`cell_sep'", "")
				local row `row'`sep'`cell_start'`cell'`cell_end'
			}
			local sep = cond(`numrow'>1, "`row_sep'", "")
			local ans "`ans'`sep'`row'`row_end'"
		}
		else {
			local row "`row_start'`topleft'" // TODO: Allow a header instead of empty or `cat'
			forval i = 1/`c(N)' {
				local inactive = inactive_`cat'[`i']
				if (!`inactive') {
					local ++numcell
					
					if ("`cat'"=="depvar") {
						local cell = varlabel[`i']	
						local footnote = footnote[`i']
						AddFootnote `footnote'
						local cell "`cell'`r(symbolcell)'"
					}
					else {
						local cell = `cat'[`i']
						cap GetMetadata cell=groups.`cat'.`cell' // Will abort if label not found
						local cell = subinstr("`template_`cat''", "@", "`cell'", .)
					}

					local n = span_`cat'[`i']
					local start_col = `offset' + `i'
					local end_col = `start_col' + `n' - 1
					local sep = cond(`numcell'>1, "`cell_sep'", "")
					local row `row'`sep'`cell_start'`cell'`cell_end'
					local line `line'`cell_line'
				}
			}
			local sep = cond(`numrow'>1, "`row_sep'", "")
			local ans "`ans'`sep'`row'`row_end'"
			qui su span_`cat'
			if (r(max)>1) {
				local ans "`ans'`line'$ENTER"
			}
			else {
				* por ahora nada, quizas midrule?
			}
		}
	}
	local ans "`ans'`header_end'"
	global quipu_header `"`ans'"'
	drop varlabel footnote
end
