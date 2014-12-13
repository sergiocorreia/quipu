// -------------------------------------------------------------------------------------------------
// ESTDB - Save and manage regr. estimates and report tables via -estout-
// -------------------------------------------------------------------------------------------------
capture program drop estdb
program define estdb
	local subcmd_list associate setpath add build_index
	* save index describe use browse list view table report

	* Remove subcmd from 0
	gettoken subcmd 0 : 0, parse(" ,")

	* Expand abbreviations and call appropiate subcommand
	if (substr("`subcmd'", 1,2)=="de") local subcmd "describe"
	if (substr("`subcmd'", 1,2)=="br") local subcmd "browse"
	if (substr("`subcmd'", 1,2)=="li") local subcmd "list"
	if (substr("`subcmd'", 1,5)=="build") local subcmd "build_index"
	local subcmd_commas : subinstr local subcmd_list " "   `"", ""', all
	assert_msg inlist("`subcmd'", "`subcmd_commas'"), msg("Valid subcommands for -estdb- are: `subcmd_list'")
	local subcmd `=proper("`subcmd'")'
	`subcmd' `0'
end

* This adds .ster extension to registry
capture program drop Associate
program define Associate
	assert_msg ("`c(os)'"=="Windows"), msg("estdb can only associate .ster files on Windows")
	local fn "associate-ster.reg"
		
	local path_binary : sysdir STATA
	local fn_binary : dir "`path_binary'" files "s*.exe", nofail
	local fn_binary `fn_binary' // Remove quotes
	local binary `path_binary'`fn_binary'
	local binary : subinstr local binary "/" "\", all
	local binary : subinstr local binary "\" "\BS\BS", all
	findfile "estdb-associate-template.reg.ado"
	local template `r(fn)'

	tempfile regfile
	local regfile "`regfile'.reg" // need a .reg extension
	filefilter "`template'" "`regfile'", from("REPLACETHIS") to("`binary'") replace
	!"`regfile'"
	cap erase "`regfile'" // Stata won't delete this due to the name change
end

capture program drop Setpath
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
		local empty = ("`files'"=="")

		if ("`replace'"=="") {
			assert_msg `empty', msg("estdb error: folder <`path'> already contains saved estimates! Use the option -append- or -replace-")
		}
		else if ("`replace'"!="" & !`empty') {
			di as text "(deleting " as result `"`path'/*.ster"' as text ")"
			local cmd = cond("`c(os)'"=="Windows", "del", "rm")
			!`cmd' "`path'/*.ster"
		}
	}
	else {
		assert_msg ("`replace'"==""), msg("estdb setpath: options -replace- and -append- are mutually exclusive")
	}
	global estdb_path `path'
end

cap pr drop View
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
end

* Run this after a command, or together with <prefix : cmd>
cap pr drop Add
program define Add, eclass
	
	* Parse
	cap _on_colon_parse `0' // * See help _prefix
	if !_rc {
		local cmd `s(after)'
		local 0 `s(before)'
	}
	syntax [, PATH(string) PREFIX(string) FILENAME(string)] [NOTEs(string)]

	* Run command
	`cmd'
	mata: st_local("notes", strtrim(`"`notes'"'))

	* Get or create filename
	if ("`filename'"=="") {
		if ("`path'"=="") local path `"$ESTPATH"'
		if ("`path'"=="") {
			di as error "Don't know where to save the .sest file! Either use path() or global ESTPATH"
			error 101
		}

		* Make up a filename
		mata: st_local("cmd_hash", strofreal(hash1(`"`e(cmdline)'"', 1e8), "%30.0f")) // `cmd'
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
			assert "`key'"!="sample" // Else -estimates- will fail
			gettoken _ notes : notes, parse("=")
			gettoken value notes : notes, quotes
			local keys `keys' `key'
			ereturn hidden local `key' `value'
		}
		ereturn hidden local keys `keys'

		ereturn hidden local ivreg2_firsteqs
		ereturn hidden local first_prefix
	}

	* FOR EACH OPT IN OPTIONS SAVE, run estimates note: key value
	estimates save "`filename'", replace

end

cap pr drop Index
program define Index
syntax anything(name=folders everything id="folder list") , save(string) keys(namelist local) [SAVEVARS(string)]
	clear
	clear results
	local i 1 // Cursor position
	gen __filename__ = "" // folder + file
	gen __file__ = ""
	gen __folder__ = ""

	foreach folder of local folders {
		
		di as text `"(parsing `folder')"'
		local files : dir "`folder'" files "*.ster"
		local n : word count `files'
		set obs `=c(N)+`n''

		foreach file of local files {
			local filename "`folder'/`file'"
			qui replace __filename__ = `"`filename'"' in `i'
			qui replace __file__ = `"`file'"' in `i'
			qui replace __folder__ = `"`folder'"' in `i'
			di as text "." _c
			estimates use "`filename'"
			
			local allkeys `keys' `e(keys)'
			local dups : list dups allkeys
			if ("`dups'"!="") {
				di as error "Duplicates in keys: `dups'"
				error 141
			}

			foreach key of local allkeys {
				cap replace `key' = "`e(`key')'" in `i'
				if (_rc==111) {
					qui gen `key' = ""
					qui replace `key' = "`e(`key')'" in `i'
				}
			}
			local ++i

			if ("`savevars'"!="") {
				local indepvars : colnames e(b)
				local depvar `e(depvar)'
				local vars `depvar' `indepvars'
				local varlist : list varlist | vars
			}

		}
		
		di _n
	}
	sort __filename__
	qui compress
	la data "ESTMGR.ADO - Index of .ster files (Stata Estimation Results)"
	save "`save'", replace
	clear

	if ("`savevars'"!="") {
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
		if ("`varlist'"!="") {
			di as error "<`varlist'>"
			exit 4321
		}
		qui gen varlabel = ""
		qui gen footnote = ""
		qui gen int sort_depvar = .
		qui gen int sort_indepvar = .
		qui save "`savevars'", replace
		cap noi merge 1:1 varname using "`savevars'_saved", keep(master match match_update) nogen nolabel nonotes update
		save, replace
		cou if varlabel==""
	}

end

cap pr drop Describe
program define Describe
syntax, index(string) [cond(string asis)] [noRESTORE]
	describe using `index', simple
	assert inlist("`restore'","", "norestore")

	if (`"`cond'"'!="") {
		if ("`restore'"=="") preserve
		di
		use if `cond' using `index', clear

		di as text "List of saved estimates:"
		forv i=1/`c(N)' {
			local fn = __filename__[`i']
			gettoken left right : fn, parse(":")
			gettoken colon right : right, parse(":")

			if ("`right'"!="") {
				di as text `"{stata estmgr view "`left'\`=char(58)'`right'" : `fn' } "'
			}
			else {
				di as text `"{stata estmgr view "`fn'" : `fn' } "'
			}
		}
		drop __*
		if (c(N)==0) exit
		foreach var of varlist _all {
			qui levelsof `var'
			local n : word count `r(levels)'
			if (`n'>1) tab `var', m sort
		} 
		if ("`restore'"=="") restore
	}

end

cap pr drop Use
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

/*
cap pr drop Browse
program define Browse
syntax

end
*/

cap pr drop List
program define List
syntax, index(string) [cond(string asis) sort(string) sort(string) sortmerge(string)] [*]
	Use, index(`index') cond(`cond') sort(`sort') sortmerge(`sortmerge')
	* estimates table est*
	forv i=1/`r(num_estimates)' {
		estimates replay _all
	}

end

cap pr drop Table
program define Table
syntax, index(string) [cond(string asis) sort(string) sortmerge(string)] [*]
	Use, index(`index') cond(`cond') sort(`sort') sortmerge(`sortmerge')
	estimates table _all , `options'
end

cap pr drop Report
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

cap pr drop GetNote
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
