* Build Index
* Notes:
* - keys() are *on top* of time, filename, path, fullpath, and the ones set when creating
* - recursive only goes ONE level deep!!!
cap pr drop Index
program define Index
	local inline 0
	if strpos(trim(`"`0'"'), "{")==1 {
		local inline 1
		local terminator = cond(strpos(trim(`"`0'"'), "{{")==1, "}}", "}")
	}
	else {
		syntax , [keys(namelist local)] /// [Recursive] -> Always on one level
			[locals(string asis)] [*] // Multiline
		if ("`options'"!="") {
			assert_msg strpos(trim(`"`options'"'), "{")==1 , msg("quipu index only allows keys(), locals(), and -{- or -{{-")
			local inline 1
			local terminator = cond(strpos(trim(`"`options'"'), "{ {")==1, "}}", "}")
		}
	}

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
	qui compress

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

	* Save index
	**sort path
	**rename path _path
	**encode _path, gen(path)
	**drop _path
	sort path filename // fullpath
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

capture program drop ProcessFolder
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
capture program drop ProcessFile
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
