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
	gen fullpath = "" // path + filename

	* Root of path
	ProcessFolder, path(`path') keys(`keys')

	* One level deep
	local folders : dir "`path'" dirs "*"
	foreach folder of local folders {
		ProcessFolder, path(`path'/`folder') keys(`keys')
	}

	* Save index
	sort fullpath
	qui compress
	la data "ESTDB.ADO - Index of .ster files (Stata Estimation Results)"
	format %tc time
	qui save "`path'/index", replace

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
	qui gen varlabel = "" // Label to be used instead of the variable
	qui gen footnote = "" // Name (keyword) of the footnote to include when using that file
	qui gen int sort_depvar = . // Order in which to show the variable columnwise (in depvars)
	qui gen int sort_indepvar = . // Order in which to show the variable rowsise (in indepvars)
	qui save "`path'/varlist_template", replace

	Update_Varlist
end

capture program drop ProcessFolder
program define ProcessFolder
	syntax, path(string) keys(string)
	
	local files : dir "`path'" files "*.ster"
	local n : word count `files'
	di as text `" - parsing <`path'>, `n' files found"'
	qui set obs `=c(N)+`n''

	foreach filename of local files {
		ProcessFile, path(`path') filename(`filename') keys(`keys')
		local indepvars : colnames e(b)
		local depvar `e(depvar)'
		local vars `depvar' `indepvars'
		local varlist : list varlist | vars
		di as text "." _c
	}
	if (`"`files'"'!="") di
	c_local varlist `varlist'
end

capture program drop ProcessFile
program define ProcessFile
syntax, path(string) filename(string) keys(string)
	local pos = c(N)
	local fullpath "`path'/`filename'"
	qui replace path = `"`path'"' in `pos'
	qui replace filename = `"`filename'"' in `pos'
	qui replace fullpath = `"`fullpath'"' in `pos'
	estimates use "`fullpath'"
	local keys `keys' `e(keys)' time
	local keys : list uniq keys

	foreach key of local keys {
		local value = e(`key')
		
		cap conf var `key'
		if (_rc==111) {
			local is_numeric = (real("`value'")!=.) | ("`value'"==".")
			local type = cond(`is_numeric', "double", "str1")
			local default = cond(`is_numeric', ".", `""""')
			qui gen `type' `key' = `default'
		}
		else {
			local type : type `key'
			if ("`type'"=="double") {
				qui replace `key' = `value' in `pos'
			}
			else {
				qui replace `key' = "`value'" in `pos'
			}
		}
	}
end
