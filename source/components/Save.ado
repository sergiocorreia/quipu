* Special case for Save to deal with multiple estimates
cap pr drop Save
program define Save, eclass
	
	* This will i) run the regression in case we are using the "quipu save : cmd" syntax, ii) save the active results
	SaveOne `0'
	local estimates "`e(stored_estimates)' `e(firsteqs)'"
	local estimates `estimates' // remove space
	assert "`prev_filename'"!=""

	if ("`estimates'"!="") {
		di as text "(saving additional stored estimates: " as result "`estimates'" as text ")"

		* Extract notes() from the syntax
		cap _on_colon_parse `0'
		if !_rc {
			local cmd `": `s(after)'"'
			local 0 `s(before)'
		}
		syntax , [PREFIX(string) FILENAME(string)] [NOTEs(string)] // note: prefix() and filename() are ignored here

		* Save each estimate
		foreach estimate of local estimates {
			qui estimates restore `estimate'
			SaveOne, filename("`prev_filename'") append notes(`notes')
		}

		* Estimates clear (we either clear them, or backup+restore what was the initial active estimate)
		estimates clear
		ereturn clear
	}
	di as text `"(estimates saved on {stata "quipu view `prev_filename'":`prev_filename'})"'
end

