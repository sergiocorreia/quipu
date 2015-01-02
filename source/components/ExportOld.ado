cap pr drop ExportOld
program define ExportOld

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









* TODO: Automate VCVNOTE
* Check the estimates for e(vce)
* e(vce) = unadjusted ols conventional ..  -> Don't say anything
* e(vcetype) = Robust, e(vce)=cluster e(clustvar)
* Robust standard errors in parentheses, clustered by individual.
* e(vcetype) = Robust, e(vce)=robust

* IDEA Include cluster vars in varlist.dta?
* AND Also probably the tsset vars?!?
