capture program drop BuildHeader
program define BuildHeader
* Save results in $estdb_header
	syntax, [header(string)]
	
	local cell_start "\multicolumn{\`n'}{c}{"
	local cell_end "}"
	local cell_sep " & "
	local cell_line "\cmidrule(lr){\`start_col'-\`end_col'}"
	local row_start "${TAB}"
	local row_end "${BACKSLASH}${BACKSLASH}${ENTER}"
	local row_sep ""
	local header_start ""
	local header_end "\midrule"
	local offset 1 // First cell in row is usually empty

	local ans "`header_start'" // Will contain the header string
	local numrow 0
	foreach cat of local header {
		local ++numrow
		local line
		local numcell 0
		if ("`cat'"=="#") {
			local row "`row_start' & "
			forval i = 1/`c(N)' {
				local cell = "(`i')"
				local n 1
				local sep = cond(`i'>1, "`cell_sep'", "")
				local row `row'`sep'`cell_start'`cell'`cell_end'
			}
			local sep = cond(`numrow'>1, "`row_sep'", "")
			local ans "`ans'`sep'`row'`row_end'"
		}
		else {
			local row "`row_start'\multicolumn{1}{l}{`cat'} & " // TODO: Fix this
			forval i = 1/`c(N)' {
				local inactive = inactive_`cat'[`i']
				if (!`inactive') {
					local ++numcell
					local cell = `cat'[`i']
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
				local ans "`ans'`line'${ENTER}"
			}
			else {
				* por ahora nada, quizas midrule?
			}
		}
	}
	local ans "`ans'`header_end'"
	global estdb_header `"`ans'"'
end
