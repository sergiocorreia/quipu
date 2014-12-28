capture program drop Update_Varlist
program define Update_Varlist
	local path $estdb_path
	assert_msg `"`path'"'!="",  msg("Path not set. Use -estdb setpath PATH- to set the global estdb_path") rc(101)
	conf file "`path'/varlist_template.dta"

	* Backup if possible
	cap copy "`path'/varlist.dta" "`path'/varlist_backup.dta", replace
	cap copy "`path'/varlist.tsv" "`path'/varlist_backup.tsv", replace

	* Load preset varlist if it exists (tab-separated for easier editing)
	cap conf file "`path'/varlist.tsv"
	if !_rc {
		
		qui import delimited "`path'/varlist.tsv", clear delim("\t") ///
			varnames(1) case(preserve) asdouble stringcols(1 2 3) numericcols(4 5)
		tempfile existing
		cap drop unused
		qui save "`existing'"

		use "`path'/varlist_template", clear
		qui merge 1:1 varname using "`existing'", keep(master match match_update using) nolabel nonotes update
		gen byte unused = _merge==2
		drop _merge
	}
	else {
		qui use "`path'/varlist_template", clear
		gen byte unused = 0
	}

	* Sort in a useful way
	sort unused sort_depvar sort_indepvar varname

	* At this point -unused- should exist
	qui cou if unused
	if r(N)==0 {
		drop unused // drop if it is redundant for the user
	}

	* Export so it can be updated
	assert varname!="" & varname!="."
	local fn "`path'/varlist.tsv"
	qui export delimited "`fn'", replace nolabel delim(tab) quote
	cap drop unused

	la data "ESTDB Table Labels - AUTOGENERATED FILE, don't update directly"
	qui save "`path'/varlist", replace
	
	*di as text "estdb: update done, you can edit " as result "`fn'"
	di as text _n "estdb: update done, you can now edit " _c
	di as smcl `"{stata "shell `fn'":`fn'}"' _c
	di as smcl `" and update any changes with {stata estdb update}"'.
	clear
end
