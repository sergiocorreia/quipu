* This just sets the folder when saving or indexing .ster files
capture program drop Setpath
program define Setpath
	syntax anything(everything name=path id=path) , [REPLACE APPEND]
	
	local path `path' // Remove the quotes
	global estdb_path // set to empty
	cap mkdir `path' // Try to create the path in case it doesn't exist

	* Check that the path is writeable
	local fn `path'/deletethis
	qui file open estdb_handle using `fn', write replace
	file close estdb_handle
	erase `fn'

	if ("`append'"=="") {
		local files : dir "`path'" files "*.ster"
		local empty = (`"`files'"'=="")

		if ("`replace'"=="") {
			assert_msg `empty', msg("estdb error: folder <`path'> already contains saved estimates! Use the option -append- or -replace-")
		}
		else if ("`replace'"!="" & !`empty') {
			local pattern "`path'/*.ster"
			local is_windows = "`c(os)'"=="Windows"
			if `is_windows' {
				local pattern : subinstr local pattern "/" "\", all
				shell del `pattern'
			}
			else {
				shell rm `pattern'
			}
			di as text "(deleted " as result `"`pattern'"' as text ")"
		}
	}
	else {
		assert_msg ("`replace'"==""), msg("estdb setpath: options -replace- and -append- are mutually exclusive")
	}
	global estdb_path `path'
end

