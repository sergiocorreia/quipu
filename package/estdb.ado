// -------------------------------------------------------------------------------------------------
// ESTDB - Save and manage regr. estimates and report tables via -estout-
// -------------------------------------------------------------------------------------------------
program define estdb
	local subcmd_list1 associate setpath add build_index update_varlist view
	local subcmd_list2 use tabulate list browse table report replay
	* save index describe use browse list view table report

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
	if ("`ifcond'"!="") {
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
end
program define Table
syntax [anything(everything)] , [*]
	estimates drop estdb*
	qui Use `anything'
	forv i=1/`c(N)' {
		local fn = path[`i'] +"/"+filename[`i']
		estimates use "`fn'"
		estimates title: "`fn'"
		estimates store estdb`i', nocopy
	}
	estimates table _all , `options'
	estimates drop estdb*
end
program define Report

* [CONSTANTS] ALl in caps
	local TAB "`=char(9)'"
	local ENTER "`=char(13)'"
	local STARS starlevels(* .05 ** .01) // * .10 ** .05 *** .01
	local CELLFORMAT b(a2) se(a2) // b(a3) ??
	local STAT_LAYOUT "\multicolumn{1}{r}{@}"
	local LAYOUT // nogaps nolines compress
	local LABELS coeflabels(_cons Constant) title(\`title') addnotes(\`notes')
	local FORMAT booktabs longtable // smcl fixed tab rtf html tex booktabs
	*local OUTPUT // replace noi type append (forces print)
	*local ORDER order(rel_newcc)
	*local WIDTH // varwidth(20)
	*local RENAME rename(rel_newcc "New Cards (banks w/store)")
	local ADVANCED `ORDER' `WIDTH' `RENAME'
	local NOTE_STAR Levels of significance: ** p\(<0.05\), ** p\(<0.01\). // *** p<0.01, ** p<0.05, * p<0.1.
	local VCVNOTE Robust standard errors in parentheses, clustered by individual.
	** local APPENDREPLACE replace

	local MGROUPS_EXTRA prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})
	local COLFORMAT C{2cm} // Will be overwritten if passed as argument.
	// Alternatives include 1) D{.}{.}{-1} with dcolumn 2) c 3) p{2cm} 4) C{2cm} with array + a custom cmd

	local PREHEAD \begin{ThreePartTable} ///
`ENTER'`TAB'\begin{TableNotes}`ENTER'`TAB'`TAB'\`footnote'`ENTER'`TAB'\end{TableNotes} ///
`ENTER'`TAB'\begin{longtable}{l*{@M}{\`colformat'}} /// {}  {c} {p{1cm}}
`ENTER'`TAB'\caption{\`title'}\label{table:\`label'} \\ ///
`ENTER'`TAB'\toprule\endfirsthead ///
`ENTER'`TAB'\midrule\endhead ///
`ENTER'`TAB'\midrule\endfoot ///
`ENTER'`TAB'\insertTableNotes\endlastfoot
	local POSTHEAD \`line_subgroup'\midrule
	local PREFOOT \midrule
	local POSTFOOT \bottomrule ///
`ENTER'\end{longtable} ///
`ENTER'\end{ThreePartTable}

* [Symbols mess]
mata: cur_symbol = 1
mata: allsymbols = tokens("\textdagger \textsection \textparagraph \textdaggerdbl 1 2 3 4 5 6 7 8 9")
mata: symboldict = asarray_create()
mata: asarray_notfound(symboldict,"")

* [PARSING]
	syntax, index(string) /// Filename with the .sest index
		labels(string) [ /// Filename with the varname/label/orders
		tex(string) /// If not set, won't save tex
		vcvnote(string) /// If set, will override the one above
		noDISP /// If not set, won't display
		cond(string asis) sort(string) ///
		title(string) ///
		group(string) grouplabel(string asis) groupnote(string asis) ///
		header(string) headerlabel(string asis) headernote(string asis) ///
		hideheader ///
		subgroup(string) subgrouplabel(string asis) /// subgroupnote(string) ///
		label(string) ///
		note(string) /// Ugly hack, need to use @ instead of ` for the local expansion
		regexrename(string asis) ///
		rename(string asis) ///
		regexdrop(string asis) ///
		drop(string asis) ///
		notedict(string) /// Name of the Mata -asarray- with the name -> description
		colformat(string) ///
		cellformat(string) ///
		DESCribe /// Will describe and exit.. useful when building the cond() part
		STATs(string) STATFormats(string) STATLabels(string asis) ///
		NOIsily] [*]
	// We still depend on the FOOT_... globals , else its too much hassle

	if ("`colformat'"=="") local colformat `COLFORMAT'
	if ("`vcvnote'"=="") local vcvnote `VCVNOTE'
	if ("`cellformat'"=="") local cellformat `CELLFORMAT'
	
* [DESCRIBE]
	if ("`describe'"!="") {
		di as result _n `"cond: <`cond'>"'
		Describe, index("`index'") cond(`cond')
		exit
	}

* [USE]
	assert ("`group'"!="") + ("`subgroup'"!="") < 2 // Can't have both!
	preserve
		Use, index("`index'") sortmerge("`labels'") cond(`cond') ///
			group(`group') grouplabel(`grouplabel') ///
			header(`header') headerlabel(`headerlabel') ///
			sort(`sort' sort_depvar depvar `subgroup') `echo'
	restore
	if ("`subgroup'"!="") local group depvar
	if ("`noisily'"!="") local echo echo
	
	assert r(num_models) > 0
	local vars `r(varlist)'
	local depvars `r(depvarlist)'
	local indepvars `r(indepvarlist)'
	local models `"`r(models)'"'
	local num_vars `r(num_vars)'
	local num_depvars `r(num_depvars)'
	local num_indepvars `r(num_indepvars)'
	local num_models `r(num_models)'
	
	local symbolcell

* [LHS Labels and groups]
	drop _all // clear destroys the labels
	qui set obs `num_models' // Better to use model as there may be be less indepvars than models if repeated
	qui gen varname = ""
	if ("`group'`header'`subgroup'"!="") qui gen __filename__ = ""

	forv i=1/`c(N)' {
		gettoken depvar depvars : depvars
		qui replace varname = "`depvar'" in `i'
		gettoken model models : models
		if ("`group'`header'`subgroup'"!="") qui replace __filename__ = `"`model'"' in `i'
	}
	gen index = _n
	qui merge m:1 varname using "`labels'", assert(match using) keep(match) nogen nolabel nonotes
	if ("`group'`header'`subgroup'"!="") qui merge m:1 __filename__ using "`index'", assert(match using) keep(match) keepusing(`group' `header' `subgroup') nogen nolabel nonotes

	sort index
	drop index

	local n_subgroup 1
	forv i=1/`c(N)' {
		local key = varname[`i']
		local value = varlabel[`i']
		local foot = footnote[`i']

		if ("`subgroup'"!="") {
			local subgroupvalue = `subgroup'[`i']
			if ("`subgrouplabel'"!="") {
				local posof : list posof "`subgroupvalue'" in subgrouplabel
				if (`posof'!=0) local subgroupvalue : word `=`posof'+1' of `subgrouplabel'
				// local subgroupvalue : label `subgrouplabel' `subgroupvalue'
			}
		}

		if ("`value'"=="") local value `key'

		local symbolcell
		GetNote, key(`foot') dict(`notedict')
		if ("`r(note)'"!="") local symbolnotes "`symbolnotes'\item[`r(symbol)'] `r(note)' `ENTER'`TAB'`TAB'"
		if ("`r(symbol)'"!="") local symbolcell "\tnote{`r(symbol)'}"

		if ("`group'"!="") {
			local _ = `group'[`i']
			if ("`_'"!=`group'[`=`i'-1']) {
				local mpattern `mpattern' 1
				* Give designed name (from local), else see if group==depvar and use that label, else keep the raw name
				
				local mgroup
				local posof : list posof "`_'" in grouplabel
				if (`posof'!=0) local mgroup : word `=`posof'+1' of `grouplabel'

				local mfoot
				local posof : list posof "`_'" in groupnote
				if (`posof'!=0) local mfoot : word `=`posof'+1' of `groupnote'

				local msymbolcell
				GetNote, key(`mfoot') dict(`notedict')
				if ("`r(note)'"!="") local symbolnotes "`symbolnotes'\item[`r(symbol)'] `r(note)' `ENTER'`TAB'`TAB'"
				if ("`r(symbol)'"!="") local msymbolcell "\tnote{`r(symbol)'}"

				if ("`mgroup'"=="" & "`group'"=="depvar") {
					local mgroup `value'
				}
				else if ("`mgroup'"=="") {
					local mgroup `_'
				}
				local mgroups `"`mgroups' "`mgroup'`msymbolcell'" "'
			}
			else {
				local mpattern `mpattern' 0
			}
		}

		* ALmost copy-paste from -groups-
		if ("`header'"!="") {
			local _ = `header'[`i']
			local hgroup
			local posof : list posof "`_'" in headerlabel
			if (`posof'!=0) local hgroup : word `=`posof'+1' of `headerlabel'

			local hfoot
			local posof : list posof "`_'" in headernote
			if (`posof'!=0) local hfoot : word `=`posof'+1' of `headernote'

			local symbolcell
			GetNote, key(`hfoot') dict(`notedict')
			if ("`r(note)'"!="") local symbolnotes "`symbolnotes'\item[`r(symbol)'] `r(note)' `ENTER'`TAB'`TAB'"
			if ("`r(symbol)'"!="") local symbolcell "\tnote{`r(symbol)'}"
			if ("`hgroup'"!="") local value `hgroup'
		}

		if ("`subgroup'"!="") {
			local depvarlabels `"`depvarlabels' "`subgroupvalue'`symbolcell'""'
		}
		else {
			local depvarlabels `"`depvarlabels' "`value'`symbolcell'""'
		}
	}

	local mlabels `"mlabels(`depvarlabels', depvars)"'
	if ("`hideheader'"!="") local mlabels mlabels(none)

* [Start RHS work]
	drop _all
	qui set obs `num_indepvars'
	qui gen varname =""
	forv i=1/`c(N)' {
		gettoken indepvar indepvars : indepvars
		qui replace varname = "`indepvar'" in `i'
	}
	qui merge 1:1 varname using "`labels'", assert(match using) keep(match) nogen nolabel nonotes

* [Drop RHS vars]
	gen byte dropit = 0
	while (`"`regexdrop'"'!="") {
		gettoken s1 regexdrop : regexdrop
		qui replace dropit = 1 if regexm(varname, "`s1'")
	}
	while (`"`drop'"'!="") {
		gettoken s1 drop : drop
		qui replace dropit = 1 if varname=="`s1'"
	}
	qui levelsof varname if dropit, local(droplist) clean
	qui drop if dropit
	drop dropit

* [Rename RHS when using groups] OR ALWAYS? BUGBUG
*if ("`group'"!="") {
if (`"`regexrename'`rename'"'!="") {
	qui gen original = varname
	while (`"`regexrename'"'!="") {
		gettoken s1 regexrename : regexrename
		gettoken s2 regexrename : regexrename
		qui replace varname = regexr(varname, "`s1'", "`s2'")
	}

	while (`"`rename'"'!="") { // Can't use estout for this because it messes up the varlabels
		gettoken s1 rename : rename
		gettoken s2 rename : rename
		qui replace varname = "`s2'" if varname=="`s1'"
	}
	gen byte renamed = original!=varname
	forv i=1/`c(N)' {
		local renamed = renamed[`i']
		assert inlist(`renamed',0,1)
		if (`renamed') {
			local renamelist `renamelist' `=original[`i']' `=varname[`i']'
		}
	}
	qui bys varname: replace footnote = "" if _N>1
	qui bys varname (renamed sort_depvar): drop if _n>1
	// If changed to an existing var, keep that (to get its varlabel)
	// Else, use the specified sort order
	drop original renamed
}

* [Add varlabels and footnotes to RHS]
	sort sort_indepvar // So dagger is for the visually first footnote, and to get the sort order
	forv i=1/`c(N)' {
		local key = varname[`i']
		local value = varlabel[`i']
		local foot = footnote[`i']
		local order `order' `key'

		local symbolcell
		GetNote, key(`foot') dict(`notedict')
		if ("`r(note)'"!="") local symbolnotes "`symbolnotes'\item[`r(symbol)'] `r(note)' `ENTER'`TAB'`TAB'"
		if ("`r(symbol)'"!="") local symbolcell "\tnote{`r(symbol)'}"
		if ("`value'"!="") local varlabels `"`varlabels' `key' "`value'`symbolcell'" "'
	}

	local varlabels varlabels(`varlabels' _cons Constant , end("" "") nolast)

* [Stats Layout]
	local numstats : word count `stats'
	forv i=1/`numstats' {
		local statlayout `statlayout' `STAT_LAYOUT'
	}
	local STATS     `"stats(`stats', fmt(`statformats') labels(`statlabels') layout(`statlayout') )"'
	local ALT_STATS `"stats(`stats', fmt(`statformats') labels(`statlabels') )"'


* [Wrap Up]
	if ("`symbolnotes'"=="") local symbolnotes "\item \relax `ENTER'`TAB'`TAB'"
	
	if ("`note'"!="") {
		local note : subinstr local note `"@"' "`=char(96)'" , all // UGLY HACK
		local note `note'
	}
	local note \Note{`vcvnote' `NOTE_STAR' `note'}

	local footnote `symbolnotes'`note'
	local opt `cellformat' `STARS' `LAYOUT' `LABELS' `OUTPUT' `ADVANCED' rename(`renamelist') drop(`droplist') // order(`order')
	if ("`disp'"!="nodisp") {
		if ("`mgroups'"!="") local full_mgroups `"mgroups(`mgroups', pattern(`mpattern'))"'
		local cmd esttab _all , varwidth(20) `ALT_STATS' `noisily' `mlabels' ///
			`full_mgroups' smcl `opt' modelwidth(30) `options' // BUGBUG
		`cmd'
		di as text _n "[FOOTNOTE] `footnote'"
	}
	*** local html_cmd  esttab _all using "$output_path/$fn.html" , `opt' $APPENDREPLACE $ALT_STATS
	if ("`tex'"!="") {
		if ("`mgroups'"!="") local full_mgroups `"mgroups(`mgroups', pattern(`mpattern') `MGROUPS_EXTRA')"'
		local cmd esttab _all using "`tex'", `opt' replace `FORMAT' `STATS' ///
			prehead(`PREHEAD') posthead(`POSTHEAD') prefoot(`PREEFOOT') postfoot(`POSTFOOT') ///
			`varlabels' `mlabels' `full_mgroups' `options'
		if ("`noisily'"!="") di as input _n `"`cmd'"' _n
		`cmd'
	}
	// estimates clear
	mata: mata drop cur_symbol allsymbols symboldict
end
program define GetNote, rclass
	syntax, [key(string) dict(string)] // dict() has the asarray() for key -> note
	return clear
	if ("`dict'"=="" | "`key'"=="") exit

	mata: st_local("symbol", asarray(symboldict, "`key'"))
	if ("`symbol'"!="") {
		return local note ""
		return local symbol "`symbol'"
		* We don't need to return the note; if the symbol already exists, it has been added
		exit
	}

	* At this point, the key has no symbol yet
	mata: st_local("symbol", allsymbols[cur_symbol++])
	cap mata: st_local("note", asarray(`dict', "`key'"))
	if _rc {
		di as error `"KEY <`key'> not found on mata asarray <`dict'> and asarray_notfound() was not set"'
		error 4321

	}
	mata: asarray(symboldict, "`key'", "`symbol'")
	if ("`note'"=="") di as error "Warning: note for `key' is empty, footnote not used"
	
	return local note "`note'"
	return local symbol "`symbol'"
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

