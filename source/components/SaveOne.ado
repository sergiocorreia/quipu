* Run this after a command, or together with <prefix : cmd>
* [SYNTAX 1] quipu save, notes(..) [prefix(..)] // after quipu setpath ..
* [SYNTAX 2] quipu save, notes(..) filename(..)
cap pr drop SaveOne
program define SaveOne, eclass
	
	* Parse (with our without colon)
	cap _on_colon_parse `0' // * See help _prefix
	if !_rc {
		local cmd `s(after)'
		local 0 `s(before)'
	}
	syntax , [PREFIX(string) FILENAME(string)] [NOTEs(string)] [APPEND]
	local has_filename = ("`filename'"!="")
	local has_prefix = ("`prefix'"!="")
	assert_msg `has_filename' + `has_prefix' < 2, msg("Can't set prefix() and filename() at the same time!")

	`cmd' // Run command (if using prefix version)
	assert_msg `"`e(cmdline)'"'!="", msg("No estimates found; e(cmdline) is empty")
	mata: st_local("notes", strtrim(`"`notes'"')) // trim (supports large strings)

	* Get or create filename
	if !`has_filename' {
		local path $quipu_path
		assert_msg `"`path'"'!="",  msg("Don't know where to save the .sest file! Use -quipu setpath PATH- to set the global quipu_path") rc(101)
		* Make up a filename
		mata: st_local("cmd_hash", strofreal(hash1(`"`e(cmdline)'"', 1e8), "%30.0f"))
		mata: st_local("obs_hash", strofreal(hash1("`c(N)'", 1e4), "%30.0f"))
		if `"`notes'"'!="" {
			mata: st_local("notes_hash", strofreal(hash1(`"`notes'"', 1e4), "%30.0f"))
			local notes_hash "`notes_hash'-"
		}
		if ("`prefix'"!="")  {
			local fn_prefix "`prefix'_"
		}
		local filename "`path'/`fn_prefix'`obs_hash'-`notes_hash'`cmd_hash'.ster"
		
	}

	* File either exists and will be replaced or doesn't exist and will be created
	cap conf new file "`filename'"
	if (_rc) qui conf file "`filename'"

	* Parse key=value options and append to ereturn as hidden
	if `"`notes'"'!="" {
		local keys
		while `"`notes'"'!="" {
			gettoken key notes : notes, parse(" =")
			assert_msg `"`notes'"'!="", msg("Error in quipu notes(): expected <key=value>, got <key>")
			assert_msg !inlist("`key'","sample","time"), msg("Key cannot be -sample- or -time-") // Else -estimates- will fail
			gettoken _ notes : notes, parse("=")
			gettoken value notes : notes, quotes
			local keys `keys' `key'
			ereturn hidden local `key' `value'
		}
		if ("`e(keys)'"!="") local existing_keys = "`e(keys)' "
		ereturn hidden local keys "`existing_keys'`keys'"
	}
	
	* Save some keys by default
	ereturn hidden local time = clock("`c(current_time)' `c(current_date)'", "hms DMY") // %tc

	local savemode = cond("`append'"=="", "replace", "append")
	qui estimates save "`filename'", `savemode'
	c_local prev_filename = "`filename'"
end

