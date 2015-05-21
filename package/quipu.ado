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
program define Assert
	* Copied from assert_msg.ado
	* Syntax: assert_msg CONDITION , [MSG(a text message)] [RC(integer return code)]
    syntax anything(everything equalok) [if] [in] [, MSG(string asis) RC(integer 9)]
    cap assert `anything' `if' `in'
    local tmp_rc = _rc
    if (`tmp_rc') {
            if (`"`msg'"'=="") local msg `" "assertion is false: `anything' `if' `in'" "'
            di as error `msg'
            exit `rc'
    }
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
	local fn `path'/DummyFile
	cap qui file open quipu_handle using `fn', write replace
	local rc = _rc
	if (`rc') {
		di as error `"quipu setpath - cannot save files in path <`path'>, does the path exist?"'
		error `rc'
	}
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


	
* Special case for Save to deal with multiple estimates
program define Save, eclass
	
	* This will i) run the regression in case we are using the "quipu save : cmd" syntax, ii) save the active results
	SaveOne `0'

	local estimates "`e(stored_estimates)'"
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


	
* Run this after a command, or together with <prefix : cmd>
* [SYNTAX 1] quipu save, notes(..) [prefix(..)] // after quipu setpath ..
* [SYNTAX 2] quipu save, notes(..) filename(..)
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
	
	* Ad-hoc: clear some locals generated by reghdfe when calling ivreg2
	ereturn hidden local ivreg2_firsteqs
	ereturn hidden local first_prefix
	
	* Save some keys by default
	ereturn hidden local time = clock("`c(current_time)' `c(current_date)'", "hms DMY") // %tc

	local savemode = cond("`append'"=="", "replace", "append")
	qui estimates save "`filename'", `savemode'
	c_local prev_filename = "`filename'"
end


	
* Build Index
* Notes:
* - keys() are *on top* of time, filename, path, fullpath, and the ones set when creating
* - recursive only goes ONE level deep!!!
program define Index
	local inline 0

	* Handle case with no options and just { or {{
	if strpos(trim(`"`0'"'), "{")==1 {
		local 0 , `0'
	}

	syntax [anything(everything)] , ///
		[TEST] /// Only load first 10 estimates per folder
		[keys(namelist local)] /// Keys to index
		[locals(string asis)] /// Locals to pass to bracket part
		[FOLDERs(string asis)] /// Subfolders to index (besides root); empty=default=all
		[*] // Multiline
	if ("`options'"!="") {
		assert_msg strpos(trim(`"`options'"'), "{")==1 , msg("quipu index unknown option: `options'")
		local inline 1
		local terminator = cond(strpos(trim(`"`options'"'), "{ {")==1, "}}", "}")
	}

	if ("`anything'"!="") {
		gettoken ifword ifcond : anything
		Assert "`ifword'"=="if"
		local if `anything'
	}

	local basepath $quipu_path
	assert_msg `"`basepath'"'!="",  msg("Path not set. Use -quipu setpath PATH- to set the global quipu_path") rc(101)
	di as text `"quipu index: saving files on <`basepath'>"'
	if ("`test'"!="") di as error `" - Warning: test mode; using only the first 10 estimates per folder"'

	// if ("`folders'"!="") {
	// 	di as text " - Note: indexing only the following subfolders:"
	// 	foreach f of local folders {
	// 		di as text "    {res}`f'"
	// 	}
	// }

	clear
	clear results
	local i 1 // Cursor position
	gen path = ""
	gen filename = ""
	gen byte num_estimate = .
	gen depvar = "" // we need this to sort the table columns (in Export.ado)
	* gen fullpath = "" // path + filename

	* Root of path
	ProcessFolder, basepath(`basepath') path() keys(`keys')
	local varlist = r(varlist)
	local varlist : list varlist | tmp_varlist

	* One level deep
	local all_folders : dir "`basepath'" dirs "*" , respectcase
	foreach folder of local all_folders {
		if ("`folders'"!="" & !`: list folder in folders') continue // Ignore folder
		ProcessFolder, `test' basepath(`basepath') path(`folder') keys(`keys')
		local tmp_varlist = r(varlist)
		local varlist : list varlist | tmp_varlist
	}

	assert_msg "`varlist'"!="", msg("quipu error: empty varlist")

	qui ds path filename vce clustvar model, not // If I destring _all and there are no subfolders, path gets converted to a byte and fails
	qui destring `r(varlist)', replace // Try to convert to numbers
	qui compress
	qui drop if missing(filename)
	assert !missing(num_estimate)

	* Add inlined block of commands
	if (`inline') {
		di as text `" - running inlined block of code"'
		while ("`locals'"!="") {
			gettoken key locals : locals, parse(" ")
			gettoken value locals : locals, parse(" ")
			local arg_keys `arg_keys' `key'
			local arg_values `"`arg_values' "`value'""'
		}
		tempfile source
		tempname fh
		qui file open `fh' using `"`source'"', write text replace
		if ("`arg_keys'"!="") file write `fh' `"qui args `arg_keys'"' _n
		local maxlines 1024
		forval i = 1/`maxlines' {
			assert_msg (`i'<`maxlines'), msg("quipu index error: maxlines (`maxlines') reached in inline block!" _n "(did you forget to close the block?)")
			qui disp _request2(_curline)
			**di as error `"[`i'] <`curline'>"'
			local trimcurline `curline' // Remove trailing comments and surrounding spaces
			if strpos(`"`trimcurline'"', "`terminator'")==1 {
				continue, break
			}
			*di as error `"[`i'] <`curline'>"'
			file write `fh' `"`macval(curline)'"' _n
		}
		qui file close `fh'
		**di as text _n "<<< Contents of inline block <<<"
		**type "`source'"
		**di as text ">>> Contents of inline block >>>" _n
		run `"`source'"' `arg_values'
		qui compress
	}

	* Apply -if-
	if ("`if'"!="") {
		qui cou `if'
		local numdrop = c(N) - r(N)
		di as text " - dropping `numdrop'/`c(N)' estimates due to -if- condition"
		qui keep `if'
	}

	* Save index
	**sort path
	**rename path _path
	**encode _path, gen(path)
	**drop _path
	sort path filename // fullpath
	order path filename /* fullpath */ time
	la data "QUIPU.ADO - Index of .ster files (Stata Estimation Results)"
	format %tc time
	
	local fn "`basepath'/index"
	qui save "`fn'", replace
	di as text `" - index saved in {stata "use `fn'":`fn'}"'

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

	local fn "`basepath'/varlist_template"
	qui save "`fn'", replace
	di as text `" - varlist template saved in {stata "use `fn'":`fn'}"'

	* Save metadata.yaml *IF* it doesn't exist already
	local fn "`basepath'/metadata.yaml"
	cap conf file "`fn'"
	if _rc==601 {
		tempname fh
		file open `fh' using `"`fn'"', write text
		file write `fh' "# [quipu] key-value metadata" _n
		file write `fh' "# comments start with a hash; empty lines are ignored" _n
		file write `fh' "# format: key: value; value can be on the next line with two extra spaces" _n
		file write `fh' "# nested dicts also require two extra spaces (no tabs!" _n
		file write `fh' _n "misc:" _n
		file write `fh' "  indicate_yes: Yes" _n
		file write `fh' "  indicate_no: no" _n
		file write `fh' _n "footnotes:" _n
		file write `fh' "  foobar: Lorem ipsum dolor sit amet." _n
		file write `fh' "  example: this is an example" _n
		file write `fh' _n "groups:" _n
		file write `fh' "  mygroup:" _n
		file write `fh' "    spam: eggs" _n
		file write `fh' "    foo: bar" _n
		file write `fh' _n "indicate:" _n
		file write `fh' "  t: Time" _n
		file write `fh' "  id: Individual" _n
		file close `fh'
		di as text `" - metadata template saved in {stata "use `fn'":`fn'}"'
	}

	Update_Varlist
end
program define ProcessFolder, rclass
	syntax, [TEST] basepath(string) [path(string)] keys(string)
	
	local bothpath = cond("`path'"=="", "`basepath'", "`basepath'/`path'")
	local files : dir "`bothpath'" files "*.ster"
	local n : word count `files'
	di as text `" - parsing <`bothpath'>, `n' files found "' _c
	local pos = c(N) // Start with current number of obs
	local new_obs = `pos' + `n' * 10 // Allow up to 10 estimation results per .sest file
	qui set obs `new_obs'

	* The following are keys that I will likely need when creating the table
	* model is used by BuildStats, clustvar used by BuildVCE
	local extrakeys time depvar vce clustvar model

	* The following are variables that I also want to keep in the varlist.dta file
	local extravars depvar vce clustvar ivar // e(absvars)? // xtreg uses ivar
	
	local i 0
	foreach filename of local files {

		local ++pos // always one estimate by file at least

		// Fill row in index.dta
		ProcessFile, basepath(`basepath') path(`path') filename(`filename') keys(`keys' `extrakeys') pos(`pos')

		local pos = `pos' + `s(extra_estimates)' // adjust for estimates beyond first
		local indepvars : colnames e(b)
		
		foreach var of local extravars {
			local `var' = cond("`e(`var')'"==".","", "`e(`var')'")
		}

		local vars `depvar' `indepvars'
		local varlist : list varlist | vars
		local ++i
		if !mod(`i',10) {
			di as text "." _c
		}
		if ("`test'"!="") & (`i'>=10) {
			continue, break
		}
	}

	if (c(N)>0) {
		conf var model
		assert_msg model!="", msg("e(model) is empty in at least one regr")
	}
	di // empty to flush line
	return local varlist `varlist'
end

* Parse a single .ster file
program define ProcessFile, sclass
syntax, basepath(string) [path(string)] filename(string) keys(string) pos(integer)
	local bothpath = cond("`path'"=="", "`basepath'", "`basepath'/`path'")
	local fullpath "`bothpath'/`filename'"


	qui estimates describe using "`fullpath'"
	local num_estimates = r(nestresults)
	assert `num_estimates'>0 & `num_estimates'<.

	forval i = 1/`num_estimates' {
		qui replace path = `"`path'"' in `pos'
		qui replace filename = `"`filename'"' in `pos'
		estimates use "`fullpath'", number(`i')
		qui replace num_estimate = `i' in `pos'
		local keys `keys' `e(keys)'
		local keys : list uniq keys
		* depvar is used to sort the table columns
		* vce and clustvar are used to build the VCV footnotes

		foreach key of local keys {
			cap qui gen `key' = ""
			qui replace `key' = "`e(`key')'" in `pos'
		}
		local ++pos
	}

	sreturn local extra_estimates = `num_estimates' - 1
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
	di as text "quipu update: done! you can now edit " _c
	di as smcl `"{stata "shell `fn'":`fn'}"' _c
	di as smcl `" and update any changes with {stata quipu update}"'.
	clear
end


	
* Replay regression
program define View, eclass
	syntax anything(name=filename) , [N(integer 0)]
	local filename : subinstr local filename `"""' "", all
	
	qui estimates describe using "`filename'"
	local num_estimates = r(nestresults)
	assert `num_estimates'>0 & `num_estimates'<.

	* Quick hack to show just the selected estimate
	local start 1
	local end `num_estimates'
	if (`n'>0) {
		local start `n'
		local end `n'
	}

	if (`num_estimates'>1 & `n'==0) di as text "(showing `num_estimates' estimates)"

	forval i = `start'/`end' {
		estimates use "`filename'", number(`i')
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
	}
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
	qui replace path = cond(path=="", "$quipu_path", "$quipu_path/" + path)
	assert_msg c(N), msg(`"condition <`if'> matched no results"') rc(2000)
	di as text "(`c(N)' estimation results loaded)"

	* Drop empty columns
	foreach var of varlist _all {
		cap qui cou if `var'!=.
		if (_rc==109) {
			qui cou if `var'!=""
		}
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
syntax [anything(everything)] , [noLIst] [*]
	qui Use `anything'
	
	di as text _n "{bf:List of keys:}"
	de, simple
	if (c(N)==0) exit

	if ("`list'"!="nolist") {
		sort path filename num_estimate
		local last_fn
		di as text _n "{bf:List of saved estimates:}"
		forv i=1/`c(N)' {
			local fn = path[`i'] +"/"+filename[`i']
			local num_estimate = num_estimate[`i']
			di %3.0f `i' _c
			if ("`last_fn'"!="`fn'") di as text `"{stata "quipu view `fn'" : `fn' } "' // , n(`num_estimate')
			local last_fn "`fn'"
		}
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
syntax [anything(everything)] , [*] [CLS]
	qui Use `anything'
	
	local more = c(more)
	if ("`cls'"!="") set more on
	cap `cls'

	forv i=1/`c(N)' {
		local fn = path[`i'] +"/"+filename[`i']
		local num_estimate = num_estimate[`i']
		if ("`cls'"=="") di
		di as text "{bf:replay `i'/`c(N)':}"
		quipu view `fn' , n(`num_estimate')
		if ("`cls'"=="") di as text "{hline}"
		if ("`cls'"!="") more
		cap `cls'
	}
	clear
	set more `more'
end
program define Table
syntax [anything(everything)] , [*]
	cap estimates drop quipu*
	qui Use `anything'
	forv i=1/`c(N)' {
		local fn = path[`i'] +"/"+filename[`i']
		local num_estimate = num_estimate[`i']
		estimates use "`fn'", number(`num_estimate')
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

