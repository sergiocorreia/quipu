* Build Index
* Notes:
* - keys() are *on top* of time, filename, path, fullpath, and the ones set when creating
* - recursive only goes ONE level deep!!!
cap pr drop Build_Index
program define Build_Index
	syntax , [keys(namelist local)] //  [Recursive] -> Always on one level
	local path $estdb_path
	assert_msg `"`path'"'!="",  msg("Path not set. Use -estdb setpath PATH- to set the global estdb_path") rc(101)
	di as text `"estdb: saving index files on <`path'>"'

	clear
	clear results
	local i 1 // Cursor position
	gen path = ""
	gen filename = ""
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
	la data "ESTDB.ADO - Index of .ster files (Stata Estimation Results)"
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
		ProcessFile, path(`path') filename(`filename') keys(`keys') pos(`++pos')
		local indepvars : colnames e(b)
		local depvar `e(depvar)'
		
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
	local keys `keys' `e(keys)' time
	local keys : list uniq keys

	foreach key of local keys {
		cap qui gen `key' = ""
		qui replace `key' = "`e(`key')'" in `pos'
	}

	*assert fullpath!="" in 1/`pos'
end