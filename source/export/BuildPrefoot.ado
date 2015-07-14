capture program drop BuildPrefoot
program define BuildPrefoot
	syntax, EXTension(string)

	if ("`extension'"=="html") {
		global quipu_prefoot "  </tbody>$ENTER$ENTER"

		local cell_start `"      <td>"'
		local cell_end "</td>${ENTER}"
		local cell_sep ""
		local cell_line

		local row_start "    <tr>${ENTER}"
		local row_end `"    </tr>${ENTER}"'
		local row_sep

		local region_start `"  <tbody class="absvars">"'
		local region_end `"  </tbody>$ENTER$ENTER"'
	}
	else {
		global quipu_prefoot "$TAB\midrule"

		local cell_start "\multicolumn{\`n'}{c}{"
		local cell_end "}"
		local cell_sep " & "
		local cell_line "\cmidrule(lr){\`start_col'-\`end_col'} "
		local row_start "${TAB}"
		local row_end "$TAB${BACKSLASH}${BACKSLASH}${ENTER}"
		local row_sep ""

		local region_start ""
		local region_end "$TAB\midrule"
	}

	*** Add rows with FEs Yes/No
	**cap ds ABSORBED_*
	**if (!_rc) {
	**	
	**	yaml local yes=metadata.misc.indicate_yes
	**	yaml local no=metadata.misc.indicate_no
	**
	**	local absvars = r(varlist)
	**	local region "`region_start'"
	**	local numrow 0
	**	foreach absvar of local absvars {
	**		local ++numrow
	**		local label : var label `absvar'
	**		local row `"`cell_start'`label'`cell_end'"'
	**		forval i = 1/`c(N)' {
	**			local cell = cond(`absvar'[`i'], "`yes'", "`no'")
	**			local row `"`row'`cell_sep'`cell_start'`cell'`cell_end'"'
	**		}
	**		local sep = cond(`numrow'>1, "`row_sep'", "")
	**		local region `"`region'`sep'`row'`row_end'"'
	**	}
	**	local region `"`region'`region_end'"'
	**}

	* Add what goes after the FEs
	if ("`extension'"=="html") {
		global quipu_prefoot `"${quipu_prefoot}`region'  <tfoot>$ENTER"'
	}
	else {
		global quipu_prefoot `"${quipu_prefoot}`region'"'
	}

end
