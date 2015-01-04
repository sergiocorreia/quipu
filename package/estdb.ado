// -------------------------------------------------------------------------------------------------
// ESTDB - Save and manage regr. estimates and export tables via -estout-
// -------------------------------------------------------------------------------------------------
program define estdb
	local subcmd_list1 associate setpath add build_index update_varlist view
	local subcmd_list2 use tabulate list browse table export replay

	* Remove subcmd from 0
	gettoken subcmd 0 : 0, parse(" ,:")

	* Expand abbreviations and call appropiate subcommand
	if (substr("`subcmd'", 1,3)=="tab" & "`subcmd'"!="table") local subcmd "tabulate"
	if (substr("`subcmd'", 1,2)=="br") local subcmd "browse"
	if (substr("`subcmd'", 1,2)=="li") local subcmd "list"
	if (substr("`subcmd'", 1,5)=="build") local subcmd "build_index"
	if (substr("`subcmd'", 1,6)=="update") local subcmd "update_varlist"

	local subcmd_commas1 : subinstr local subcmd_list1 " "   `"", ""', all
	local subcmd_commas2 : subinstr local subcmd_list2 " "   `"", ""', all
	assert_msg inlist("`subcmd'", "`subcmd_commas1'") | inlist("`subcmd'", "`subcmd_commas2'"), ///
	 	msg("Valid subcommands for -estdb- are: " as input "`subcmd_list1' `subcmd_list2'")
	local subcmd `=proper("`subcmd'")'
	`subcmd' `0'
end

	
* Associate .ster files with stata, so you can double click and view them
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


	
* This just sets the folder when saving or indexing .ster files
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


	
* Run this after a command, or together with <prefix : cmd>
* [SYNTAX 1] estdb add, notes(..) [prefix(..)] // after estdb setpath ..
* [SYNTAX 2] estdb add, notes(..) filename(..)
program define Add, eclass
	
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
		local path $estdb_path
		assert_msg `"`path'"'!="",  msg("Don't know where to save the .sest file! Use -estdb setpath PATH- to set the global estdb_path") rc(101)
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
	local path $estdb_path
	assert_msg `"`path'"'!="",  msg("Path not set. Use -estdb setpath PATH- to set the global estdb_path") rc(101)
	di as text `"estdb: saving index files on <`path'>"'

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

	* Save metadata.txt *IF* it doesn't exist already
	local fn "`path'/metadata.txt"
	cap conf file "`fn'"
	if _rc==601 {
		tempname fh
		file open `fh' using `"`fn'"', write text
		file write `fh' "* Key-Value Metadata for ESTDB" _n
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
		
		local extravars depvar clustvar ivar // e(absvars)? // xtreg uses ivar
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
	local path $estdb_path
	assert_msg `"`path'"'!="",  msg("Path not set. Use -estdb setpath PATH- to set the global estdb_path") rc(101)
	
	* BUGBUG: preserve+restore?
	qui use `if' using "`path'/index", clear
	assert_msg c(N), msg("condition <`if'> matched no results") rc(2000)
	di as text "(`c(N)' estimation results loaded)"

	foreach var of varlist _all {
		cap qui cou if `var'!=.
		if (_rc==109) qui cou if `var'!=""
		if (r(N)==0) drop `var'
	}
end

/*cap pr drop Use
program define Use, rclass
syntax, index(string) [cond(string asis) ///
	group(string) grouplabel(string asis) ///
	header(string) headerlabel(string asis) ///
	sort(string) sortmerge(string) echo]
estimates clear
if (`"`cond'"'!="") local cond if `cond'

	qui use `cond' using "`index'", clear
	di as text ("(loading `c(N)' estimation results)")

	if ("`sortmerge'"!="" & "`sort'"!="") {
		rename depvar varname
		qui merge m:1 varname using "`sortmerge'", keep(master match) nogen nolabel nonotes keepusing("sort_depvar")
		rename varname depvar
	}

	if ("`group'"!="" | "`header'"!="") local sort `group' `header' __precedence__ `sort'

	if ("`group'"!="") {
		qui gen int __precedence__ = . // Lower values will be sorted first (aka to the left of the table)
		local i 0
		while (`"`grouplabel'"'!="") {
			gettoken s1 grouplabel : grouplabel
			gettoken s2 grouplabel : grouplabel
			qui replace __precedence__ = `++i' if `group'=="`s1'"
			qui replace `group' = "`s2'" if `group'=="`s1'"
		}
	}

	if ("`header'"!="") {
		cap qui gen int __precedence__ = . // Will do nothing if -group- is set
		replace __precedence__ =  100 * __precedence__
		local i 0
		while (`"`headerlabel'"'!="") {
			gettoken s1 headerlabel : headerlabel
			gettoken s2 headerlabel : headerlabel
			qui replace __precedence__ = `++i' if `header'=="`s1'"
			qui replace `header' = "`s2'" if `header'=="`s1'"
		}
	}

	if ("`sort'"!="") sort `sort'
	cap drop __precedence__

	conf str var __filename__
	keep __filename__

	forv i=1/`c(N)' {
		local fn = __filename__[`i']
		estimates use `fn'
		if ("`echo'"!="") noi di as text "[CMD]" _n as result `"`e(cmdline)'"' _n

		local indepvars : colnames e(b)
		local depvar `e(depvar)'
		local vars `depvar' `indepvars'
		local varlist : list varlist | vars
		local depvarlist `depvarlist' `depvar'
		local indepvarlist : list indepvarlist | indepvars
		local models `"`models' "`fn'""'

		estimates title: `fn'
		estimates store est`i', nocopy

	}
	
	local varcons _cons
	local varlist : list varlist - varcons
	local indepvarlist : list indepvarlist - varcons

	local numvars : list sizeof varlist
	local numdepvars : list sizeof depvarlist
	local numindepvars : list sizeof indepvarlist
	
	return scalar num_models = c(N)
	return scalar num_vars = `numvars'
	return scalar num_depvars = `numdepvars'
	return scalar num_indepvars = `numindepvars'

	return local varlist `varlist'
	return local depvarlist `depvarlist'
	return local indepvarlist `indepvarlist'
	return local models `"`models'"'
	clear
end

*/
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
		di as text `"{stata "estdb view `fn'" : `fn' } "'
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
		estdb view "`fn'"
		di as text "{hline}"
	}
	clear
end
program define Table
syntax [anything(everything)] , [*]
	cap estimates drop estdb*
	qui Use `anything'
	forv i=1/`c(N)' {
		local fn = path[`i'] +"/"+filename[`i']
		estimates use "`fn'"
		estimates title: "`fn'"
		estimates store estdb`i', nocopy
	}
	clear
	estimates table _all , `options'
	estimates drop estdb*
end
program define Export
syntax [anything(everything)] , as(string) [*]
	
	* Extract the optional -using- part from the -if-
	while (`"`anything'"'!="") {
		gettoken tmp anything : anything
		if ("`tmp'"=="using") {
			gettoken filename anything : anything

			* Remove extension (which will be ignored!)
			foreach ext in tex htm html pdf {
				local filename : subinstr local filename ".`ext'" ""
			}

			* Remove quotes (will include by default)
			local filename `filename'

			* Windows shell can't handle "/" folder separators:
			if c(os)=="Windows" {
				local filename = subinstr(`"`filename'"', "/", "\", .)
			}
			
			local ifcond `ifcond' `anything'
			continue, break
		}
		else {
			local ifcond `ifcond' `tmp'

		}
	}

	* Check the as() strings and convert as(html) into -> html(filename.html)
	foreach format in `as' {
		assert_msg inlist("`format'", "tex", "pdf", "html"), msg("<`format'> is an invalid output format")
	}

	* Set constants, globals, etc. (do just after parsing)
	SetConstants

	* Load Estimates (and sort them, save $indepvars)
	cap estimates drop estdb*
	qui Use `ifcond'
	LoadEstimates

	* Export table
	ExportInner, filename(`filename') `as' `options'
	
	* Cleanup
	estimates drop estdb*
	CleanConstants
	global ESTDB_DEBUG
end
program define LoadEstimates
	* Load estimates in the order set by varlist.dta (wrt depvar)
	rename depvar varname
	qui merge m:1 varname using "${estdb_path}/varlist", keep(master match) keepusing(sort_depvar) nogen nolabel nonotes
	sort sort_depvar
	drop sort_depvar varname
	assert "${indepvars}"==""

	forv i=1/`c(N)' {
		local fn = path[`i'] +"/"+filename[`i']
		estimates use "`fn'"
		estimates title: "`fn'"

		local indepvars : colnames e(b)
		local indepvarlist : list indepvarlist | indepvars

		estimates store estdb`i', nocopy
	}

	global indepvars `indepvarlist'
	clear
end
program define ExportInner
syntax, [FILEname(string) /// Path+name of output file; ideally w/out extension
		HTML TEX PDF /// What are the desired output formats?
		VERBOSE(integer 0) /// 0=No Logging, 2=Log Everything
		VIEW /// Open the PDF viewer at the end?
		LATEX_engine(string) /// xelatex (smaller pdfs, better fonts) or pdflatex (faster)
		COLFORMAT(string) /// Alternatives include 1) D{.}{.}{-1} with dcolumn 2) c 3) p{2cm} 4) C{2cm} with array + a custom cmd
		VCVnote(string) /// Note regarding std. errors, in case default msg is not good enough
		title(string) ///
		label(string) /// Used in TeX labels
		] [*]

	if (`verbose'>0) global ESTDB_DEBUG 1
	if (`verbose'>1) local noisily noisily 
	if ("`latex_engine'"=="") local latex_engine "xelatex"
	assert_msg inlist("`latex_engine'", "xelatex", "pdflatex"), msg("invalid latex engine: `latex_engine'")

	* Load metadata
	if (`verbose'>1) di as text "(loading metadata)"
	mata: read_metadata()

	local using = cond("`filename'"=="","", `"using "`filename'.tex""')
	local base_cmd esttab estdb* `using' , `noisily' ///
		varlabels(\`rhslabels') order(`rhsorder')
	local tex_options longtable booktabs ///
		prehead(\`prehead') posthead(\`posthead') prefoot(\`prefoot') postfoot(\`postfoot') substitute(\`substitute')

	local footnote // \item[\textdagger] Number of large retail stores opened in a district in quarters \(t\) or \(t+1\). // Placeholder
	local line_subgroup // What was this?

	* Set header/footer locals
	if ("`colformat'"=="") local colformat C{2cm}
	if (`"`footnote'"'!="") local insert_notes "\insertTableNotes"

	* Substitute characters conflicting with latex
	local specialchars _ % $ // Latex special characters (don't substitute \ so we can insert math with \( \) )
	foreach char in `specialchars' {
		local substitute `substitute' `char' $BACKSLASH`char'
	}
	local substitute `substitute' "\_cons " \_cons

	local prehead \centering /// Prevent centering captions that fit in single lines; don't put it in the preamble b/c that makes normal tables look ugly
$ENTER\captionsetup{singlelinecheck=false,labelfont=bf,labelsep=newline,font=bf,justification=justified} /// Different line for table number and table title
$ENTER\begin{ThreePartTable} ///
$ENTER$TAB\begin{TableNotes}$ENTER$TAB$TAB`footnote'$ENTER$TAB\end{TableNotes} ///
$ENTER$TAB\begin{longtable}{l*{@M}{`colformat'}} /// {}  {c} {p{1cm}}
$ENTER$TAB\caption{\`title'}\label{table:`label'} \\ ///
$ENTER$TAB\toprule\endfirsthead ///
$ENTER$TAB\midrule\endhead ///
$ENTER$TAB\midrule\endfoot ///
$ENTER$TAB`insert_notes'\endlastfoot
	local posthead `line_subgroup'\midrule
	local prefoot \midrule
	local postfoot \bottomrule ///
$ENTER\end{longtable} ///
$ENTER\end{ThreePartTable}

	* Testing..
	GetMetadata mylocal=debug
	GetMetadata another=footnotes.growth
	di as text "mylocal=<`mylocal'>"
	di as text "another=<`another'>"

	GetRHSVarlabels // Options saved in locals: rhslabels->varlabels rhsorder->order +- +-

	* Save PDF
	if ("`pdf'"!="") {
		qui findfile estdb-top.tex.ado
		local fn_top = r(fn)
		qui findfile estdb-bottom.tex.ado
		local fn_bottom = r(fn)
		local pdf_options top(`fn_top') bottom(`fn_bottom')
		RunCMD `base_cmd' `tex_options' `pdf_options' `options'

		* Compile
		if ("`filename'"!="") {
			local args latex_engine(`latex_engine') filename(`filename') verbose(`verbose')
			cap erase "`filename'.log"
			cap erase "`filename'.aux"
			CompilePDF, `args'
			CompilePDF, `args' // longtable often requires a rerun
			di as text `"(output written to {stata "shell `filename'.pdf":`filename'.pdf})"'
			if ("`view'"!="") RunCMD shell `filename'.pdf
			cap erase "`filename'.log"
			cap erase "`filename'.aux"
		}
	}

	* Save TEX (after .pdf so it overwrites the interim tex file there)
	if ("`tex'"!="") {
		RunCMD `base_cmd' `tex_options' `pdf_options' `options'
	}
end
program define GetRHSVarlabels
	local indepvars $indepvars
	local N : word count `indepvars'
	qui set obs `N'
	qui gen varname =""

	* Fill -varname- and merge to get variable labels
	forv i=1/`N' {
		gettoken indepvar indepvars : indepvars
		qui replace varname = "`indepvar'" in `i'
	}
	qui merge m:1 varname using "${estdb_path}/varlist", keep(master match) keepusing(varlabel footnote sort_indepvar) nogen nolabel nonotes

	* List of RHS variables to drop/hide
	* ...

	* Groups +-+-
	* ...

	* Set varlabel option
	sort sort_indepvar // orders RHS, and ensures footnote daggers will be in order
	forv i=1/`N' {
		local key = varname[`i']
		local value = varlabel[`i']
		local foot = footnote[`i']
		local order `order' `key'

		*local symbolcell
		*GetNote, key(`foot') dict(`notedict')
		*if ("`r(note)'"!="") local symbolnotes "`symbolnotes'\item[`r(symbol)'] `r(note)' `ENTER'`TAB'`TAB'"
		*if ("`r(symbol)'"!="") local symbolcell "\tnote{`r(symbol)'}"
		if ("`value'"!="") local varlabels `"`varlabels' `key' "`value'`symbolcell'" "'
	}

	drop _all // BUGBUG: clear?
	*local varlabels varlabels(`varlabels' _cons Constant , end("" "") nolast)
	local varlabels `varlabels' _cons Constant , end("" "") nolast

	c_local rhslabels `varlabels'
	c_local rhsorder `order'
end
program define CompilePDF
	syntax, filename(string) verbose(integer) latex_engine(string)
	
	* Get folder
	local tmp `filename'
	local left
	local dir
	while strpos("`tmp'", "/")>0 | strpos("`tmp'", "\")>0 {
		local dir `dir'`left' // if we run this at the end of the while, we will keep the /
		gettoken left tmp : tmp, parse("/\")
	}

	tempfile stderr stdout
	cap erase "`filename'.pdf" // I don't want to BELIEVE there is no bug
	if (`verbose'<=1) local quiet "-quiet"
	RunCMD shell `latex_engine' "`filename'.tex" -halt-on-error `quiet' -output-directory="`dir'" 2> "`stderr'" 1> "`stdout'" // -quiet
	if (`verbose'>1) noi type "`stderr'"
	if (`verbose'>1) di as text "{hline}"
	if (`verbose'>1) noi type "`stdout'"
	cap conf file "`filename'.pdf"
	if _rc==601 {
		di as error "(pdf could not be created - run with -verbose(2)- to see details)"
		exit 601
	}
end
program define RunCMD
	if "$ESTDB_DEBUG"!="" {
		di as text "[cmd] " as input `"`0'"'
	}
	`0'
end
program define SetConstants
	global TAB "`=char(9)'"
	global ENTER "`=char(13)'"
	global BACKSLASH "`=char(92)'"
	global indepvars // Ensure it's empty
end
program define CleanConstants
	* TODO: Ensure this function always get called when -Export- fails (like -reghdfe- does)
	global TAB
	global ENTER
	global BACKSLASH
	global indepvars
end
program define GetMetadata
* Syntax: GetMetadata MyLocal=key -> Will store metadata[key] in the local MyLocal
	local lclkey `0'
	if ("`lclkey'"=="") error 100
	gettoken lcl lclkey: lclkey , parse("=")
	gettoken equalsign key: lclkey , parse("=")
	local key `key' // Remove blanks
	assert_msg "`key'"!="", msg("Key is empty! args=<`0'>")
	mata: st_local("key_exists", strofreal(asarray_contains(metadata, "`key'")))
	assert inlist(`key_exists', 0, 1)
	assert_msg `key_exists'==1, msg("metadata[`key'] does not exist")
	mata: st_local("value", asarray(metadata, "`key'"))
	c_local `lcl' = "`value'"
end

	
// -------------------------------------------------------------------------------------------------
// Import metadata.txt (kinda-markdown-syntax with metadata for footnotes, etc.)
// -------------------------------------------------------------------------------------------------
mata:
mata set matastrict off

void read_metadata()
{
	external metadata
	fn = st_global("estdb_path") + "/" + "metadata.txt"
	fh = fopen(fn, "r")
	metadata = asarray_create() // container dict
	headers = J(1, 5, "")
	level = 0
	i = 0
	is_verbose = st_local("verbose")!="0"

	while ( ( line = strtrim(fget(fh)) ) != J(0,0,"") ) {
		//  Ignore comments
		if ( strpos(line, "*")==1 | strlen(line)==0 ) continue

		// Remove leading dash
		if (substr(line, 1, 1)=="-") {
			line = strtrim(substr(line, 2, .))
		}

		// Check that the line contents are not empty
		assert(strlen(subinstr(line, "#", "", .)))
		// metadata[header1.header2...key] = value
		if ( strpos(line, "#")!=1 ) {
			_ = regexm(line, "^[ \t]?([a-zA-Z0-9_]+)[ \t]?:(.+)$")
			if (_==0) {
				printf("{txt}key:value line could not be parsed <" + line + ">")
			}
			assert (_==1)
			assert(strlen(strtrim(regexs(1)))>0)
			assert(strlen(strtrim(regexs(2)))>0)
			headers[level+1] = regexs(1)
			value = strtrim(regexs(2))
			key = invtokens(headers[., (1..level+1)], ".")
			assert(asarray_contains(metadata, key)==0) // assert key not in metadata
			++i
			asarray(metadata, key, value) // metadata[key] = value
			// printf("metadata.%s=<%s>\n", key, value)
		}
		// Get header and level
		else {
			_ = regexm(line, "^(#+)(.+)")
			level = strlen(regexs(1))
			headers[level] = strtrim(regexs(2))
		}
	}
	fclose(fh)
	if (is_verbose) {
		printf("{txt}(%s key-value pairs added to estdb metadata)\n", strofreal(i))
	}
}
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

