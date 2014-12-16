* Associate .ster files with stata, so you can double click and view them
capture program drop Associate
program define Associate
	assert_msg ("`c(os)'"=="Windows"), msg("estdb can only associate .ster files on Windows")
	local fn "associate-ster.reg"
		
	local path_binary : sysdir STATA
	local fn_binary : dir "`path_binary'" files "s*.exe", nofail
	local minlen = .
	
	* Imperfect workaround to multiple files
	foreach f of local fn_binary {
		local len = length("`f'")
		if (`len'<`minlen') {
			local minlen `len'
			local best `f'
		}
	}
	local fn_binary `best'
	*local fn_binary : word 1 of `fn_binary'

	local fn_binary `fn_binary' // Remove quotes
	local binary `path_binary'`fn_binary'
	local binary : subinstr local binary "/" "\", all
	di as text "Stata binary: `binary'"
	local binary : subinstr local binary "\" "\BS\BS", all
	qui findfile "estdb-associate-template.reg.ado"
	local template `r(fn)'

	tempfile regfile
	local regfile "`regfile'.reg" // need a .reg extension
	filefilter "`template'" "`regfile'", from("REPLACETHIS") to("`binary'") replace
	di as text "Running .reg file: `regfile'"
	!"`regfile'"
	cap erase "`regfile'" // Stata won't delete this due to the name change
end
