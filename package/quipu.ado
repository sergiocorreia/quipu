// -------------------------------------------------------------------------------------------------
// QUIPU - Save and manage regr. estimates and export tables via -estout-
// -------------------------------------------------------------------------------------------------
program define quipu
	local subcmd_list1 associate setpath save index update_varlist view
	local subcmd_list2 use tabulate list browse table export replay

	* Remove subcmd from 0
	gettoken subcmd 0 : 0, parse(" ,:")

	* Expand abbreviations and call appropiate subcommand
	if (substr("`subcmd'", 1,3)=="tab" & "`subcmd'"!="table") local subcmd "tabulate"
	if (substr("`subcmd'", 1,2)=="br") local subcmd "browse"
	if (substr("`subcmd'", 1,2)=="li") local subcmd "list"
	if (substr("`subcmd'", 1,5)=="build") local subcmd "index"
	if (substr("`subcmd'", 1,6)=="update") local subcmd "update_varlist"

	local subcmd_commas1 : subinstr local subcmd_list1 " "   `"", ""', all
	local subcmd_commas2 : subinstr local subcmd_list2 " "   `"", ""', all
	assert_msg inlist("`subcmd'", "`subcmd_commas1'") | inlist("`subcmd'", "`subcmd_commas2'"), ///
	 	msg("Valid subcommands for -quipu- are: " as input "`subcmd_list1' `subcmd_list2'")
	local subcmd `=proper("`subcmd'")'
	if ("`subcmd'"=="Export") local subcmd quipu_export
	`subcmd' `0'
end

	
* Associate .ster files with stata, so you can double click and view them
program define Associate
	assert_msg ("`c(os)'"=="Windows"), msg("quipu can only associate .ster files on Windows")
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
	qui findfile "quipu-associate-template.reg.ado"
	local template `r(fn)'

	tempfile regfile
	local regfile "`regfile'.reg" // need a .reg extension
	filefilter "`template'" "`regfile'", from("REPLACETHIS") to("`binary'") replace
	di as text "Running .reg file: `regfile'"
	!"`regfile'"
	cap erase "`regfile'" // Stata won't delete this due to the name change
end


	
* This just sets the folder when saving or indexing .ster files
program define Setpath
	syntax anything(everything name=path id=path) , [REPLACE APPEND]
	
	local path `path' // Remove the quotes
	global quipu_path // set to empty
	cap mkdir `path' // Try to create the path in case it doesn't exist

	* Check that the path is writeable
	local fn `path'/deletethis
	qui file open quipu_handle using `fn', write replace
	file close quipu_handle
	erase `fn'

	if ("`append'"=="") {
		local files : dir "`path'" files "*.ster"
		local empty = (`"`files'"'=="")

		if ("`replace'"=="") {
			assert_msg `empty', msg("quipu error: folder <`path'> already contains saved estimates! Use the option -append- or -replace-")
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
		assert_msg ("`replace'"==""), msg("quipu setpath: options -replace- and -append- are mutually exclusive")
	}
	global quipu_path `path'
end


	
* Run this after a command, or together with <prefix : cmd>
* [SYNTAX 1] quipu save, notes(..) [prefix(..)] // after quipu setpath ..
* [SYNTAX 2] quipu save, notes(..) filename(..)
program define Save, eclass
	
	* Parse (with our without colon)
	cap _on_colon_parse `0' // * See help _prefix
	if !_rc {
		local cmd `s(after)'
		local 0 `s(before)'
	}
	syntax , [PREFIX(string) FILENAME(string)] [NOTEs(string)]
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

	* File either exists and will be replaced or doesnt' exist and will be created
	cap conf new file "`filename'"
	if (_rc) qui conf file "`filename'"

	* Parse key=value options and append to ereturn as hidden
	if `"`notes'"'!="" {
		local keys
		while `"`notes'"'!="" {
			gettoken key notes : notes, parse(" =")
			assert_msg !inlist("`key'","sample","time"), msg("Key cannot be -sample- or -time-") // Else -estimates- will fail
			gettoken _ notes : notes, parse("=")
			gettoken value notes : notes, quotes
			local keys `keys' `key'
			ereturn hidden local `key' `value'
		}
		ereturn hidden local keys `keys'
	}
	
	* Ad-hoc: clear some locals generated by reghdfe when calling ivreg2
	ereturn hidden local ivreg2_firsteqs
	ereturn hidden local first_prefix
	
	* Save some keys by default
	ereturn hidden local time = clock("`c(current_time)' `c(current_date)'", "hms DMY") // %tc
	ereturn hidden local filename = "`filename'"

	estimates save "`filename'", replace
end


	
* Build Index
* Notes:
* - keys() are *on top* of time, filename, path, fullpath, and the ones set when creating
* - recursive only goes ONE level deep!!!
program define Build_Index
	syntax , [keys(namelist local)] //  [Recursive] -> Always on one level
	local path $quipu_path
	assert_msg `"`path'"'!="",  msg("Path not set. Use -quipu setpath PATH- to set the global quipu_path") rc(101)
	di as text `"quipu: saving index files on <`path'>"'

	clear
	clear results
	local i 1 // Cursor position
	gen path = ""
	gen filename = ""
	gen depvar = "" // we need this to sort the table columns (in Export.ado)
	* gen fullpath = "" // path + filename

	* Root of path
	ProcessFolder, path(`path') keys(`keys')

	* One level deep
	local folders : dir "`path'" dirs "*"
	foreach folder of local folders {
		ProcessFolder, path(`path'/`folder') keys(`keys')
		local tmp_varlist = r(varlist)
		local varlist : list varlist | tmp_varlist
	}
	qui destring _all, replace // Try to convert to numbers

	* Save index
	**sort path
	**rename path _path
	**encode _path, gen(path)
	**drop _path
	sort path filename // fullpath
	qui compress
	order path filename /* fullpath */ time
	la data "QUIPU.ADO - Index of .ster files (Stata Estimation Results)"
	format %tc time
	
	local fn "`path'/index"
	qui save "`fn'", replace
	di as text `"index saved in {stata "use `fn'":`fn'}"'

	* Deal with indicator variables by just using the root variable
	* (else with many indicators it becomes a mess)
	local newvarlist
	while "`varlist'"!="" {
		gettoken var varlist : varlist, parse(" ")
		while strpos("`var'", ".")>0 {
			gettoken tmp var : var, parse(".")
		}
		*di as text "<`var'> <`varlist'>"
		local newvarlist `newvarlist' `var'
	}
	local varlist : list uniq newvarlist

	* Save template of varlist
	clear
	local varcons _cons
	local varlist : list varlist - varcons
	local varlist : list sort varlist
	local numvars : list sizeof varlist
	qui set obs `numvars'
	qui gen varname = ""
	forv i=1/`numvars' {
		gettoken var varlist : varlist
		qui replace varname = "`var'" in `i'
	}
	assert_msg ("`varlist'"==""), msg("varlist not empty: <`varlist'>")
	assert varname!="" & varname!="."

	qui gen varlabel = "" // Label to be used instead of the variable
	qui gen footnote = "" // Name (keyword) of the footnote to include when using that file
	qui gen int sort_depvar = . // Order in which to show the variable columnwise (in depvars)
	qui gen int sort_indepvar = . // Order in which to show the variable rowsise (in indepvars)

	local fn "`path'/varlist_template"
	qui save "`fn'", replace
	di as text `"varlist template saved in {stata "use `fn'":`fn'}"'

	Update_Varlist

	* Save metadata.txt *IF* it doesn't exist already
	local fn "`path'/metadata.txt"
	cap conf file "`fn'"
	if _rc==601 {
		tempname fh
		file open `fh' using `"`fn'"', write text
		file write `fh' "* Key-Value Metadata for QUIPU" _n
		file write `fh' "*  - You can set headers with #, ##, etc." _n
		file write `fh' "*  - Set key-value pairs with key:value (dash before is optional)" _n _n
		file write `fh' "somekey: Some value" _n _n
		file write `fh' "anotherkey: Another value" _n _n
		file write `fh' "#footnotes" _n _n
		file write `fh' " - foobar: Lorem ipsum dolor sit amet." _n
		file write `fh' " - example: this is an example" _n _n
		file write `fh' "#groups" _n _n
		file write `fh' "##mygroup" _n _n
		file write `fh' " - spam: eggs" _n
		file write `fh' " - foo: bar" _n
		file write `fh' _n
		file close `fh'
		di as text `"metadata template saved in {stata "use `fn'":`fn'}"'
	}
end
program define ProcessFolder, rclass
	syntax, path(string) keys(string)
	
	local files : dir "`path'" files "*.ster"
	local n : word count `files'
	di as text `" - parsing <`path'>, `n' files found "' _c
	local pos = c(N) // Start with current number of obs
	qui set obs `=`pos'+`n''

	local i 0
	foreach filename of local files {
		ProcessFile, path(`path') filename(`filename') keys(`keys') pos(`++pos') // Fill row in index.dta
		local indepvars : colnames e(b)
		
		* model used by BuildStats, clustvar used by BuildVCE
		local extravars depvar clustvar ivar model // e(absvars)? // xtreg uses ivar
		foreach var of local extravars {
			local `var' = cond("`e(`var')'"==".","", "`e(`var')'")
		}

		local vars `depvar' `indepvars'
		local varlist : list varlist | vars
		local ++i
		if !mod(`i',10) {
			di as text "." _c
		}
	}
	di // empty to flush line
	return local varlist `varlist'
end

* Parse a single .ster file
program define ProcessFile
syntax, path(string) filename(string) keys(string) pos(integer)
	local fullpath "`path'/`filename'"
	qui replace path = `"`path'"' in `pos'
	qui replace filename = `"`filename'"' in `pos'
	* qui replace fullpath = `"`fullpath'"' in `pos'
	estimates use "`fullpath'"
	local keys `keys' `e(keys)' time depvar vce clustvar
	local keys : list uniq keys
	* depvar is used to sort the table columns
	* vce and clustvar are used to build the VCV footnotes

	foreach key of local keys {
		cap qui gen `key' = ""
		qui replace `key' = "`e(`key')'" in `pos'
	}
	*assert fullpath!="" in 1/`pos'
end
program define Update_Varlist
	local path $quipu_path
	assert_msg `"`path'"'!="",  msg("Path not set. Use -quipu setpath PATH- to set the global quipu_path") rc(101)
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

	la data "QUIPU Table Labels - AUTOGENERATED FILE, don't update directly"
	qui save "`path'/varlist", replace
	
	*di as text "quipu: update done, you can edit " as result "`fn'"
	di as text _n "quipu: update done, you can now edit " _c
	di as smcl `"{stata "shell `fn'":`fn'}"' _c
	di as smcl `" and update any changes with {stata quipu update}"'.
	clear
end


	
* Replay regression
program define View, eclass
	local filename `0'
	estimates use "`filename'"
	if "`e(keys)'"!="" {
		di as text "{title:Classification}"
		foreach key in `e(keys)' {
			local ans `ans' as text " `key'=" as result "`e(`key')'"
		}
		di `ans' _n
	}
	di as text "{title:Command}"
	di as input `"`e(cmdline)'"' _n
	di as text "{title:Estimation Results}"
	`e(cmd)' // -estimates replay- writes an unwanted title row

	/*
	local keys = e(keys)
	if ("`keys'"!="") {
		di as text _n "{title:Saved Notes}"
		foreach key of local keys {
			di as text " `key' = " as result "`e(`key')'"
		}
	}
	*/
end
program define Use, rclass
	* Parse (including workaround that allows to use if <cond> with variables not in dataset)
	estimates clear
	syntax [anything(name=ifcond id="if condition" everything)]
	if (`"`ifcond'"'!="") {
		gettoken ifword ifcond : ifcond
		assert_msg "`ifword'"=="if", msg("condition needs to start with -if-") rc(101)
		local if "if`ifcond'"
	}
	local path $quipu_path
	assert_msg `"`path'"'!="",  msg("Path not set. Use -quipu setpath PATH- to set the global quipu_path") rc(101)
	
	qui use `if' using "`path'/index", clear
	assert_msg c(N), msg("condition <`if'> matched no results") rc(2000)
	di as text "(`c(N)' estimation results loaded)"

	foreach var of varlist _all {
		cap qui cou if `var'!=.
		if (_rc==109) qui cou if `var'!=""
		if (r(N)==0) drop `var'
	}
end
program define List
syntax [anything(everything)] , [*]
	qui Use `anything'
	qui ds path filename time, not
	list `r(varlist)' , `options' constant
	return clear
end

/*
 [cond(string asis) sort(string) sort(string) sortmerge(string)] [*]
	Use, index(`index') cond(`cond') sort(`sort') sortmerge(`sortmerge')
	* estimates table est*
	forv i=1/`r(num_estimates)' {
		estimates replay _all
	}

end

*/
program define Browse
syntax [anything(everything)]
	qui Use `anything'
	browse
end
program define Tabulate
syntax [anything(everything)] , [*]
	qui Use `anything'
	
	di as text _n "{bf:List of keys:}"
	de, simple
	if (c(N)==0) exit

	di as text _n "{bf:List of saved estimates:}"
	forv i=1/`c(N)' {
		local fn = path[`i'] +"/"+filename[`i']
		di %3.0f `i' _c
		di as text `"{stata "quipu view `fn'" : `fn' } "'
	}

	drop path filename time
	di as text _n "{bf:Tabulates of keys that vary across estimates:}"
	foreach var of varlist _all {
		qui levelsof `var'
		local n : word count `r(levels)'
		if (`n'>1) tab `var', m sort `options'
	} 
end

/*
syntax, index(string) [cond(string asis)] [noRESTORE]
	Tabulate using `index', simple
	assert inlist("`restore'","", "norestore")

	if (`"`cond'"'!="") {
		if ("`restore'"=="") preserve
		di
		use if `cond' using `index', clear

		gettoken left right : fn, parse(":")
		gettoken colon right : right, parse(":")

		if ("`right'"!="") {
			di as text `"{stata estmgr view "`left'\`=char(58)'`right'" : `fn' } "'
		}
		else {
			di as text `"{stata estmgr view "`fn'" : `fn' } "'
		}
		}
*/
program define Replay
syntax [anything(everything)] , [*]
	qui Use `anything'
	forv i=1/`c(N)' {
		local fn = path[`i'] +"/"+filename[`i']
		di as text _n "{bf:replay `i'/`c(N)':}"
		quipu view "`fn'"
		di as text "{hline}"
	}
	clear
end
program define Table
syntax [anything(everything)] , [*]
	cap estimates drop quipu*
	qui Use `anything'
	forv i=1/`c(N)' {
		local fn = path[`i'] +"/"+filename[`i']
		estimates use "`fn'"
		estimates title: "`fn'"
		estimates store quipu`i', nocopy
	}
	clear
	estimates table _all , `options'
	estimates drop quipu*
end


	
// -------------------------------------------------------------
// Simple assertions (not element-by-element on variables) with informative messages
// -------------------------------------------------------------
* SYNTAX: assert_msg CONDITION , [MSG(a text message)] [RC(integer return code)]

program define assert_msg
	syntax anything(everything equalok) [, MSG(string asis) RC(integer 198)]
	* Using -asis- so I can pass strings combined with "as text|etc" keywords
	* USELESS HACK/TRICK: assert_msg 0, msg(as text "foo!") rc(0) -> Same as display
	if !(`anything') {
		if (`"`msg'"'!="") {
			di as error `msg'
			exit `rc'
		}
		else {
			error `rc'
		}
	}
end

