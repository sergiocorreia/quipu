capture program drop BuildHeader
program define BuildHeader
syntax [anything(name=header equalok everything)] , EXTension(string) [Fmt(string asis)]

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
		
		local cell_start `"      <th colspan="\`n'">"'
		local cell_end "</th>${ENTER}"
		local cell_sep ""
		local cell_line // "\cmidrule(lr){\`start_col'-\`end_col'} "

		local row_start "    <tr>${ENTER}"
		local row_end `"    </tr>${ENTER}"'
		local row_sep
		
		local header_start "  <thead>${ENTER}"
		local header_end "  </thead>${ENTER}"
		local offset 1 // First cell in row is usually empty
		local topleft "      <th></th>${ENTER}"
		local topleft_auto `"`topleft'"'

		local linestart ""
		local lineend ""
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

		local linestart "$TAB"
		local lineend "${ENTER}"
	}

	local ans "`header_start'" // Will contain the header string
	local numrow 0
	foreach cat of local header {
		local ++numrow
		local line "`linestart'"
		local numcell 0
		if ("`cat'"=="autonumeric") {
			local row `"`row_start'`topleft_auto'"'
			forval i = 1/`c(N)' {
				local cell = subinstr("`template_`cat''", "@", "`i'", .)
				local n 1
				local sep = cond(`i'>1, "`cell_sep'", "")
				local row `"`row'`sep'`cell_start'`cell'`cell_end'"'
			}
			local sep = cond(`numrow'>1, "`row_sep'", "")
			local ans `"`ans'`sep'`row'`row_end'"'
		}
		else {

			qui su span_`cat'
			local is_group = (r(max)>1)
			assert inlist(`is_group', 0, 1)

			local row `"`row_start'`topleft'"' // TODO: Allow a header instead of empty or `cat'
			forval i = 1/`c(N)' {
				local inactive = inactive_`cat'[`i']
				if (!`inactive') {
					local ++numcell
					
					if ("`cat'"=="depvar") {
						local cell = varlabel[`i']	
						local footnote = footnote[`i']
						AddFootnote, ext(`extension') footnote(`footnote')
						local cell "`cell'`r(symbolcell)'"
					}
					else {
						local cell = `cat'[`i']
						cap yaml local cell=metadata.groups.`cat'.`cell' // Will abort if label not found
						local cell = subinstr("`template_`cat''", "@", "`cell'", .)
					}

					local n = span_`cat'[`i']
					local start_col = `offset' + `i'
					local end_col = `start_col' + `n' - 1
					local sep = cond(`numcell'>1, "`cell_sep'", "")
					
					if ("`extension'"=="html" & `is_group') {
						local row `"`row'`sep'`cell_start'<p class="underline">`cell'</p>`cell_end'"'
					}
					else {
						local row `"`row'`sep'`cell_start'`cell'`cell_end'"'
						local line `line'`cell_line'
					}
				}
			}
			local sep = cond(`numrow'>1, "`row_sep'", "")
			
			if ("`extension'"!="html" & `is_group') {
				local ans "`ans'`sep'`row'`row_end'`line'`lineend'"
			}
			else {
				local ans "`ans'`sep'`row'`row_end'"
			}
		}
	}
	local ans "`ans'`header_end'"
	global quipu_header `"`ans'"'
	drop varlabel footnote
end
