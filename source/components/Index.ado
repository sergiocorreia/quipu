* Build Index
* Notes:
* - keys() are *on top* of time, filename, path, fullpath, and the ones set when creating
* - recursive only goes ONE level deep!!!
cap pr drop Index
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
		file write `fh' "# nested dicts also require two extra spaces (no tabs!" _n _n
		file write `fh' "misc:" _n _n
		file write `fh' "  indicate_yes: Yes" _n
		file write `fh' "  indicate_no: no" _n
		file write `fh' "footnotes:" _n _n
		file write `fh' " foobar: Lorem ipsum dolor sit amet." _n
		file write `fh' " example: this is an example" _n _n
		file write `fh' "groups:" _n _n
		file write `fh' "  mygroup:" _n _n
		file write `fh' "    spam: eggs" _n
		file write `fh' "    foo: bar" _n
		file write `fh' "indicate:" _n _n
		file write `fh' "  t: Time" _n _n
		file write `fh' "  id: Individual" _n _n
		file write `fh' _n
		file close `fh'
		di as text `" - metadata template saved in {stata "use `fn'":`fn'}"'
	}
	
	Update_Varlist
end

capture program drop ProcessFolder
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
capture program drop ProcessFile
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
