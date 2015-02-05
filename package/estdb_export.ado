// -------------------------------------------------------------------------------------------------
// QUIPU_EXPORT - Exports the Estimation Tables
// -------------------------------------------------------------------------------------------------
/// SYNTAX
/// quipu export [using] [if] , as(..) [quipu_options] [esttab_options] [estout_options]
program define quipu_export
	*preserve
	nobreak {
		Cleanup // Ensure globals start empty
		cap noi break Export `0'
		if (_rc) {
			local rc = _rc
			*BUGBUG Cleanup
			exit `rc'
		}
	}
	*restore
end

// Outer Subroutines
program define Export
	Parse `0'
	
	Initialize, metadata(`metadata') // Define globals and mata objects (including the metadata)
	Use `ifcond' // Load selected estimates
	LoadEstimates `header' // Loads estimates and sort them in the correct order

	BuildPrehead, colformat(`colformat') title(`title') label(`label') ifcond(`"`ifcond'"') orientation(`orientation') size(`size')	
	BuildHeader `header' // Build header and saves it in $quipu_header (passed to posthead)
	BuildStats `stats'
	BuildVCENote, vcenote(`vcenote') // This clears the data!
	clear // Do after (BuildHeader, BuildStats). Do before (BuildRHS)
	BuildRHS, rename(`rename') drop(`drop') // $quipu_rhsoptions -> rename() drop() varlabels() order()
	BuildPrefoot
	BuildPostfoot, orientation(`orientation') size(`size') `pagebreak'
	BuildFootnotes, notes(`notes') stars(`stars') // Updates $quipu_footnotes

	if ($quipu_verbose>1) local noisily noisily
	local prepost prehead($quipu_prehead) posthead($quipu_header) prefoot($quipu_prefoot) postfoot($quipu_postfoot)
	local base_opt `noisily' $quipu_rhsoptions $quipu_starlevels mlabels(none) nonumbers `cellformat' ${quipu_stats} `prepost'
	if ("`html'"!="") BuildHTML, filename(`filename') `base_opt' `options'
	if ("`pdf'"!="") BuildPDF, filename(`filename') latex_engine(`latex_engine') `view' `base_opt' `options'
	if ("`tex'"!="") BuildTEX, filename(`filename') `base_opt' `options'  // Run after PDF so it overwrites the .tex file
	
	Cleanup
end
program define Parse
	syntax [anything(everything)] , ///
		as(string) /// tex pdf html
		[VERBOSE(integer 0) /// 0=No Logging, 2=Log Everything
		VIEW /// Open the PDF viewer at the end?
		LATEX_engine(string) /// xelatex (smaller pdfs, better fonts) or pdflatex (faster)
		SIZE(integer 5) ORIENTation(string) PAGEBREAK /// More PDF options
		COLFORMAT(string) /// Alternatives include 1) D{.}{.}{-1} with dcolumn 2) c 3) p{2cm} 4) C{2cm} with array + a custom cmd
		NOTEs(string) /// Misc notes (i.e. everything besides the glossaries for symbols, stars, and vcv)
		VCEnote(string) /// Note regarding std. errors, in case default msg is not good enough
		TITLE(string) ///
		LABEL(string) /// Used in TeX labels
		RENAME(string asis) /// This is for REGEX replaces, which encompass normal ones. Note we are matching entire strings (adding ^$)
		DROP(string asis) /// REGEX drops, which encompass normal ones.
		HEADER(string asis) /// Each word will indicate a row in the header. Valid ones are either in e() or #.
		METAdata(string asis) /// Additional metadata to override the one from the markdown file
		STARs(string) /// Cutoffs for statistical significance
		CELLFORMAT(string) /// Decimal format of coefs and SDs
		STATs(string asis) ///
		Order(string asis) VARLabels(string asis) /// ESTOUT TRAP OPTIONS: Will be silently ignored!
		] [*]
	* Note: Remember to update any changes here before the bottom c_local!

	assert_msg inlist("`verbose'", "0", "1", "2"), msg("Wrong verbose level (needs to be 0, 1 or 2)")
	global quipu_verbose `verbose'

	* Syntax can't handle -if- ot in dataset
	* Will save locals filename (path+filename, w/out extension) and ifcond
	ParseUsingIf `anything'

	* Validate contents of as()
	foreach format in `as' {
		assert_msg inlist("`format'", "tex", "pdf", "html"), msg("<`format'> is an invalid output format")
		local `format' `format'
	}
	
	* Set default options
	if ("`header'"=="") local header depvar #
	if ("`colformat'"=="") local colformat C{2cm}
	if ("`latex_engine'"=="") local latex_engine "xelatex"
	assert_msg inlist("`latex_engine'", "xelatex", "pdflatex"), msg("invalid latex engine: `latex_engine'")
	if ("`orientation'"=="") local orientation "portrait"
	assert_msg inlist("`orientation'", "landscape", "portrait"), msg("invalid page orientation (needs to be landscape or portrait)")
	assert_msg inrange(`size', 1, 10), msg("invalid table size (needs to be an integer between 1 and 10)")
	if ("`stars'"=="") local stars "0.10 0.05 0.01" // 0.05 0.01 ??
	foreach cutoff of local stars {
		assert_msg real("`cutoff'")<. , msg("invalid cutoff: `cutoff' (not a number)")
		assert_msg inrange(`cutoff', 0.0, 1.0) , msg("invalid cutoff: `cutoff' (outside [0-1])")
	}
	if ("`cellformat'"=="") local cellformat "b(a2) se(a2)"
	
	* Inject values into caller (Export.ado)
	local names filename ifcond tex pdf html view latex_engine orientation size pagebreak ///
		colformat notes stars vcenote title label stats ///
		rename drop header cellformat metadata options
	if ($quipu_verbose>1) di as text "Parsed options:"
	foreach name of local names {
		if (`"``name''"'!="") {
			if ($quipu_verbose>1) di as text `"  `name' = "' as result `"``name''"'
			c_local `name' `"``name''"'
		}
	}
end
program define ParseUsingIf
	while (`"`0'"'!="") {
		gettoken tmp 0 : 0
		if ("`tmp'"=="using") {
			gettoken filename 0 : 0
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
			local ifcond `ifcond' `0'
			continue, break
		}
		else {
			local ifcond `ifcond' `tmp'
		}
	}
	c_local filename `filename'
	c_local ifcond   `ifcond'
end
program define Initialize
	syntax, [METAdata(string asis)]

	global TAB "`=char(9)'"
	global ENTER "`=char(13)'"
	global BACKSLASH "`=char(92)'"
	
	* Load metadata
	if ($quipu_verbose>1) di as text "(loading metadata)"
	mata: read_metadata()

	* Additional metadata from the options
	while (`"`metadata'"'!="") {
		gettoken lhs metadata : metadata
		gettoken rhs metadata : metadata
		SetMetadata `lhs'=`rhs'
	}

	* Clear potentialy possible previous estimates (from e.g. a failed run)
	cap estimates drop quipu*

	* Symbol mess
	mata: symboltoken = tokeninit()
	mata: symbols = "\textdagger \textsection \textparagraph \textdaggerdbl 1 2 3 4 5 6 7 8 9"
	mata: tokenset(symboltoken, symbols)
	mata: symboldict = asarray_create() // dict: footnote -> symbol (for already used footnotes)
	* USAGE: mata: st_local("symbol", tokenget(symboltoken))  ... then assert_msg "`symbol'"!=""
end

	
* Clear globals, mata objects, and saved estimates
program define Cleanup
	* TODO: Ensure this function always get called when -Export- fails (like -reghdfe- does)
	global TAB
	global ENTER
	global BACKSLASH
	global indepvars
	global quipu_verbose

	global quipu_prehead
	global quipu_header
	global quipu_footnotes
	global quipu_insertnote
	global quipu_rhsoptions
	global quipu_prefoot
	global quipu_postfoot
	global quipu_starlevels
	global quipu_vcenote
	global quipu_stats

	clear
	cap estimates drop quipu*
	local mata_objects metadata symboltoken symbols symboldict
	foreach obj of local mata_objects {
		cap mata: mata drop `obj'
	}
end
program define LoadEstimates
syntax [anything(name=header equalok everything)] [ , Fmt(string asis)]

	* Load estimates in the order set by varlist.dta (wrt depvar)
	rename depvar varname
	qui merge m:1 varname using "${quipu_path}/varlist", keep(master match) keepusing(sort_depvar) nogen nolabel nonotes
	rename varname depvar
	assert "${indepvars}"=="" // bugbug drop

	* "#" will be ignored when sorting
	local autonumeric #
	local header : list header - autonumeric

	* Variables that we need to construct from the estimates
	qui ds
	local existing_variables = r(varlist)
	local newvars : list header - existing_variables
	foreach var of local newvars {
		qui gen `var' = ""
	}
	forv i=1/`c(N)' {
		local fn = path[`i'] +"/"+filename[`i']
		estimates use "`fn'"
		foreach var of local newvars {
			qui replace `var' = "`e(`var')'" in `i'
		}
		estimates drop .
	}

	* Sort the dataset (columns of table will reflect that)
	local groups
	foreach var of local header {
		if ("`var'"!="depvar") qui gen byte sort_`var' = .
		cap GetMetadata cats=header.sort.`var'
		assert inlist(_rc, 0, 510)
		if (!_rc) {
			local i 0
			while ("`cats'"!="") {
				gettoken cat cats : cats
				qui replace sort_`var' = `++i' if "`var'"=="`cat'"
			}
		}

		bys `groups' sort_`var' `var': gen byte _group_`var' = _n==1
		qui replace _group_`var' = sum(_group_`var')
		local groups `groups' _group_`var'
	}

	sort `groups'
	gen byte _index_ = _n

	foreach var of local header {
		bys _group_`var': gen byte span_`var' = _N
		bys _group_`var' (_index_): gen byte inactive_`var' = _n>1
		order `var' sort_`var' span_`var' inactive_`var', last
	}

	sort `groups' // Redundant
	drop _group_*

	* Load estimates
	forv i=1/`c(N)' {
		local fn = path[`i'] +"/"+filename[`i']
		estimates use "`fn'"
		estimates title: "`fn'"
		local indepvars : colnames e(b)
		local indepvarlist : list indepvarlist | indepvars
		estimates store quipu`i', nocopy
	}
	global indepvars `indepvarlist'
end


// Building Blocks
program define BuildPrehead
syntax, colformat(string) orientation(string) size(integer) [title(string) label(string) ifcond(string asis)]

	local hr = 32 * "*"
    local size_names tiny scriptsize footnotesize small normalsize large Large LARGE huge Huge
    local size_colseps 04 11 11 30 30 30 30 30 30 30 // 04 = 0.04cm

	local bottom = cond(`size'<=2, 2, 3)
	if ("`orientation'"=="landscape") {
		local wrapper "\newgeometry{bottom=`bottom'cm}$ENTER\begin{landscape}$ENTER\setlength\LTcapwidth{\textwidth}"
	}
	else {
		local wrapper "{"
	}
    local size_name : word `size' of `size_names'
    local size_colseps : word `size' of `size_colseps'

	global quipu_prehead $ENTER\begin{comment} ///
		"$TAB`hr' QUIPU - Stata Regression `hr'" ///
		`"$TAB - Criteria: `ifcond'"' ///
		`"$TAB - Estimates: ${quipu_path}"' ///
		"\end{comment}" ///
		"`wrapper'" ///
		"$BACKSLASH`size_name'" ///
		"\tabcolsep=0.`size_colseps'cm" ///
		"\centering" /// Prevent centering captions that fit in single lines; don't put it in the preamble b/c that makes normal tables look ugly
		"\captionsetup{singlelinecheck=false,labelfont=bf,labelsep=newline,font=bf,justification=justified}" /// Different line for table number and table title
		"\begin{ThreePartTable}" ///
		"$TAB\begin{TableNotes}$ENTER$TAB$TAB\${quipu_footnotes}$ENTER$TAB\end{TableNotes}" ///
		"$TAB\begin{longtable}{l*{@M}{`colformat'}}" /// {}  {c} {p{1cm}}
		"$TAB\caption{`title'}\label{table:`label'} \\" ///
		"$TAB\toprule\endfirsthead" ///
		"$TAB\midrule\endhead" ///
		"$TAB\midrule\endfoot" ///
		"$TAB\${quipu_insertnote}\endlastfoot"
end
program define BuildHeader
syntax [anything(name=header equalok everything)] [ , Fmt(string asis)]

	* Set replacement locals
	local header : subinstr local header "#" "autonumeric", word
	foreach cat of local header {
		if ("`cat'"=="autonumeric") {
			local template_`cat' "(@)"
		}
		else {
			local template_`cat' "@"
		}
	}
	while ("`fmt'"!="") {
		gettoken cat fmt : fmt
		gettoken template fmt : fmt
		local template_`cat' "`template'"
	}

	rename depvar varname
	qui merge m:1 varname using "${quipu_path}/varlist", keep(master match) nogen nolabel nonotes ///
		 keepusing(varlabel footnote)
	sort _index_ // rearrange
	rename varname depvar
	qui replace varlabel = depvar if missing(varlabel)

	local cell_start "\multicolumn{\`n'}{c}{"
	local cell_end "}"
	local cell_sep " & "
	local cell_line "\cmidrule(lr){\`start_col'-\`end_col'} "
	local row_start "${TAB}"
	local row_end "$TAB${BACKSLASH}${BACKSLASH}${ENTER}"
	local row_sep ""
	local header_start ""
	local header_end "$TAB\midrule"
	local offset 1 // First cell in row is usually empty

	local ans "`header_start'" // Will contain the header string
	local numrow 0
	foreach cat of local header {
		local ++numrow
		local line "$TAB"
		local numcell 0
		if ("`cat'"=="autonumeric") {
			local row "`row_start'\multicolumn{1}{c}{} & "
			forval i = 1/`c(N)' {
				local cell = subinstr("`template_`cat''", "@", "`i'", .)
				local n 1
				local sep = cond(`i'>1, "`cell_sep'", "")
				local row `row'`sep'`cell_start'`cell'`cell_end'
			}
			local sep = cond(`numrow'>1, "`row_sep'", "")
			local ans "`ans'`sep'`row'`row_end'"
		}
		else {
			local row "`row_start'\multicolumn{1}{l}{} & " // TODO: Allow a header instead of empty or `cat'
			forval i = 1/`c(N)' {
				local inactive = inactive_`cat'[`i']
				if (!`inactive') {
					local ++numcell
					
					if ("`cat'"=="depvar") {
						local cell = varlabel[`i']	
						local footnote = footnote[`i']
						AddFootnote `footnote'
						local cell "`cell'`r(symbolcell)'"
					}
					else {
						local cell = `cat'[`i']
						cap GetMetadata cell=groups.`cat'.`cell' // Will abort if label not found
						local cell = subinstr("`template_`cat''", "@", "`cell'", .)
					}

					local n = span_`cat'[`i']
					local start_col = `offset' + `i'
					local end_col = `start_col' + `n' - 1
					local sep = cond(`numcell'>1, "`cell_sep'", "")
					local row `row'`sep'`cell_start'`cell'`cell_end'
					local line `line'`cell_line'
				}
			}
			local sep = cond(`numrow'>1, "`row_sep'", "")
			local ans "`ans'`sep'`row'`row_end'"
			qui su span_`cat'
			if (r(max)>1) {
				local ans "`ans'`line'$ENTER"
			}
			else {
				* por ahora nada, quizas midrule?
			}
		}
	}
	local ans "`ans'`header_end'"
	global quipu_header `"`ans'"'
	drop varlabel footnote
end
program define BuildPrefoot
	global quipu_prefoot "$TAB\midrule"
end
program define BuildVCENote
syntax, [vcenote(string)]
	if ("`vcenote'"=="") {
		qui levelsof vce, missing local(vce) clean
		if inlist("`vce'", "unadjusted") local vce "ols"
		if !inlist("`vce'", "ols", "robust", "cluster") {
			di as error "(cannot autogenerate vce note for vcetype <`vce'>, use -vcenote- option if you don't want it empty)"
		}
		else if ("`vce'"=="ols") {
			global quipu_vcenote "Standard errors in parentheses"
		}
		else if ("`vce'"=="robust") {
			global quipu_vcenote "Robust standard errors in parentheses"
		}
		else if ("`vce'"=="cluster") {
			qui levelsof clustvar, missing local(clustvar) clean
			local cond = `"inlist(varname, ""' + subinstr("`clustvar'", "#", `"", ""', .) + `"")"'
			qui use varname varlabel if `cond' using "${quipu_path}/varlist", clear
			qui replace varlabel = varname if missing(varlabel)
			forval i = 1/`c(N)' {
				local sep = cond(`i'==1, "", cond(`i'==c(N), " and ", ", "))
				local varlabel = varlabel[`i']
				local clustlabel `clustlabel'`sep'`varlabel'
			}
			global quipu_vcenote "Robust standard errors in parentheses, clustered by `clustlabel'."
		}
	}

	if "$quipu_vcenote"=="" {
		global quipu_vcenote "`vcenote'"
	}
	clear // Because we -use-d the dataset
end
program define BuildRHS
syntax, [rename(string asis) drop(string asis)]

	local indepvars $indepvars
	local N : word count `indepvars'
	qui set obs `N'
	qui gen varname =""

	* Fill -varname- and merge to get variable labels
	forv i=1/`N' {
		gettoken indepvar indepvars : indepvars
		qui replace varname = "`indepvar'" in `i'
	}
	qui merge m:1 varname using "${quipu_path}/varlist", keep(master match) nogen nolabel nonotes ///
		keepusing(varlabel footnote sort_indepvar sort_depvar)

	* Drop variables
	if (`"`drop'"'!="") {
		gen byte dropit = 0
		while (`"`drop'"'!="") {
			gettoken s1 drop : drop
			qui replace dropit = 1 if regexm(varname, "^`s1'$")
		}
		qui levelsof varname if dropit, local(rhsdrop) clean
		if ($quipu_verbose>0) di as text "(dropping variables: " as result "`rhsdrop'" as text ")"
		qui drop if dropit
		drop dropit
	}

	* Rename variables
	* Note: Can't use estout for simple renames b/c it messes up the varlabels
		* TODO (PERO DEMASIADO ENREDADO): permitir usar regexs()..
		* basicamente, hacer primero una pasada con regexm, luego aplicar regexr que permita sumar regexs(1)
	if (`"`rename'"'!="") {
		qui gen original = varname
		while (`"`rename'"'!="") {
			gettoken s1 rename : rename
			gettoken s2 rename : rename
			assert_msg `"`s2'"'!="", msg("rename() must have an even number of strings")
			qui replace varname = regexr(varname, "^`s1'$", "`s2'")
		}
		gen byte renamed = original!=varname
		forv i=1/`c(N)' {
			local renamed = renamed[`i']
			if (`renamed') {
				local rhsrename `rhsrename' `=original[`i']' `=varname[`i']'
				if ($quipu_verbose>0) {
					local notice `"`notice' as text " `=original[`i']'" as result " `=varname[`i']'""'
				}
			}
		}

		if (`"`rhsrename'"'!="") {
			if ($quipu_verbose>0) di as text "(renaming variables:" `notice' as text ")"

			* We don't want the labels of a renamed variable (else, why did we rename it?)
			replace varlabel = "" if renamed
			replace footnote = "" if renamed

			* By renaming we can end up with multiple vars:
			* Remove conflicting footnotes (+-)
			*qui bys varname (footnote): replace footnote = "" if _N>1 & footnote[1]!=footnote[_N]

			* Remove duplicate varnames (prioritize nonrenamed vars)
			qui bys varname (renamed sort_depvar): drop if _n>1
		}

		drop original renamed
	}

	* Groups +-+-
	* ...

	* Set varlabel option
	sort sort_indepvar // orders RHS, and ensures footnote daggers will be in order
	forv i=1/`N' {
		local varname = varname[`i']
		local varlabel = cond(varlabel[`i']=="", "`varname'", varlabel[`i'])
		local footnote = footnote[`i']
		local order `order' `varname'
		AddFootnote `footnote'
		local varlabels `"`varlabels' `varname' "`varlabel'`r(symbolcell)'" "'
	}

	drop _all // BUGBUG: clear?
	*local varlabels varlabels(`varlabels' _cons Constant , end("" "") nolast)
	local varlabels `"`varlabels' _cons Constant , end("" "") nolast"'

	* Set global option
	global quipu_rhsoptions varlabels(`varlabels') order(`order') rename(`rhsrename') drop(`rhsdrop')
end
program define BuildStats
syntax [anything(name=stats equalok everything)] [ , Fmt(string) Labels(string asis)]

	local DEFAULT_STATS_all N
	local DEFAULT_STATS_ols r2 r2_a
	local DEFAULT_STATS_iv idp widstat jp
	*local DEFAULT_STATS_fe
	*local DEFAULT_STATS_re

	* If no override, use defaults
	local default "default"
	local use_default : list default in stats
	if (`use_default') {
		local stats : list stats - default
		local morestats `stats'
	}
	if ("`stats'"=="" | `use_default') {
		qui levelsof model, local(models) clean
		local stats `DEFAULT_STATS_all'
		foreach model of local models {
			if ("`DEFAULT_STATS_`model''"!="") {
				local stats `stats' `DEFAULT_STATS_`model''
			}
		}
	}
	if (`use_default') local stats `stats' `morestats'
	if ($quipu_verbose>1) di as text "(stats included: " as result "`stats'" as text ")"

	* List of common stats with their label and desired format
	local labels_N			"Observations"
	local labels_N_clust	"Num. Clusters"
	local labels_df_a		"Num. Fixed Effects"
	local labels_r2		"R\(^2\)"
	local labels_r2_a		"Adjusted R\(^2\)"
	local labels_idp		"Underid. P-val. (KP LM)"
	local labels_widstat	"Weak id. F-stat (KP Wald)"
	local labels_jp		"Overid. P-val (Hansen J)"

	local fmt_N			%12.0gc
	local fmt_N_clust	%12.0gc
	local fmt_df_a		%12.0gc
	local fmt_r2		%6.4f
	local fmt_r2_a		%6.4f
	local fmt_idp		%6.3fc
	local fmt_widstat	%6.2fc
	local fmt_jp		%6.3fc

	local DEFAULT_FORMAT a3

	* Underidentification test (Kleibergen-Paap rk LM statistic) = idstat iddf idp
	* Weak identification test (Kleibergen-Paap rk Wald F statistic) = e(widstat) // stock-yogo?
	* Hansen J statistic (overidentification test of all instruments) =  e(jp)  e(jdf)  e(j)
		// The joint null hypothesis is that the instruments are valid instruments
		// A rejection casts doubt on the validity of the instruments.

	* Parse received fmt and labels, to override defaults
	foreach cat in fmt labels {
		local args `"``cat''"'
		while (`"`args'"'!="") {
			gettoken key args : args
			gettoken val args : args
			local `cat'_`key' `val'
		}
	}

	* Parse stats
	foreach stat of local stats {
		local statlbl = cond(`"`labels_`stat''"'!="", `"`labels_`stat''"', "`stat'")
		local statfmt = cond(`"`fmt_`stat''"'!="", `"`fmt_`stat''"', "`DEFAULT_FORMAT'")
		local statlabels `"`statlabels' "`statlbl'""'
		local statformats `"`statformats' `statfmt'"'
	}

	local layout "\multicolumn{1}{r}{@} "
	local numstats : word count `stats'
	local statlayout = "`layout'" * `numstats'

	global quipu_stats `"stats(`stats', fmt(`statformats') labels(`statlabels') layout(`statlayout') )"'
end
program define BuildFootnotes
syntax, stars(string) [notes(string)] [vcnote(string)]
	* BUGBUG: Autoset starnote and vcnote!!!

	local stars : list sort stars // Sort it
	local numstars : word count `stars'
	local starnote "Levels of significance: "
	forval i = `numstars'(-1)1 {
		local sign = "*" * `=`numstars'-`i'+1'
		local num : word `i' of `stars'
		local sep = cond(`i'>1, ", ", ".")
		local starnote "`starnote' `sign' \(p<`num'\)`sep'"
		local starlevels "`starlevels' `sign' `num'"
	}

	local sep1 = cond("${quipu_vcenote}"!="" & "`starnote'`note'"!="", " ", "")
	local sep2 = cond("${quipu_vcenote}`starnote'"!="" & "`note'"!="", " ", "")
	local note "\Note{${quipu_vcenote}`sep1'`starnote'`sep2'`note'}"

	if (`"${quipu_footnotes}"'!="") {
		global quipu_footnotes `"${quipu_footnotes}${ENTER}$TAB$TAB`note'"'
	}
	else {
		global quipu_footnotes `"`note'"'
	}

	* ThreePartTable fails w/out footnotes (although above we are kinda ensuring it will not be empty)
	if (`"$quipu_footnotes"'!="") global quipu_insertnote "\insertTableNotes"
	global quipu_starlevels starlevels(`starlevels')
end
program define BuildPostfoot
syntax, orientation(string) size(integer) [PAGEBREAK]

	if ("`orientation'"=="landscape") {
		local wrapper "\vspace{-5pt}$ENTER\end{landscape}"
	}
	else {
		local wrapper "\vspace{15pt}$ENTER}"
	}

	* clearpage vs newpage http://tex.stackexchange.com/questions/45609/is-it-wrong-to-use-clearpage-instead-of-newpage
	local flush = cond("`pagebreak'"!="", "$ENTER\newpage", "")

	global quipu_postfoot $TAB\bottomrule ///
		"$TAB\end{longtable}" ///
		"\end{ThreePartTable}" ///
		"`wrapper'" ///
		"\restoregeometry`flush'"
end

	
* Receive a keyword, looks it up, and i) returns the symbol, ii) updates the global with the footnotes
program define AddFootnote, rclass
	local footnote `0'
	if ("`footnote'"=="") {
		return local symbol ""
		exit
	}
	GetMetadata definition=footnotes.`footnote'
	* Use existing symbols for footnotes previously used
	mata: st_local("footnote_exists", strofreal(asarray_contains(symboldict, "`footnote'")))
	if (`footnote_exists') {
		mata: st_local("symbol", asarray(symboldict, "`footnote'"))
		assert_msg "`footnote'"!="", msg("footnote unexpectedly empty")
	}
	else {
		mata: st_local("symbol", tokenget(symboltoken))
		mata: asarray(symboldict, "`footnote'", "`symbol'")
		assert_msg ("`symbol'"!=""), msg("we run out of footnote symbols")
		global quipu_footnotes "${quipu_footnotes}\item[`symbol'] `definition'`ENTER'`TAB'`TAB'"
	}
	local symbolcell "\tnote{`symbol'}"
	return local symbolcell "`symbolcell'"
end
program define BuildHTML
syntax, filename(string) [*]
	di as error "NOT YET SUPPORTED"
	error 1234
end
program define BuildTEX
syntax, filename(string) [*]

	* Substitute characters conflicting with latex
	local specialchars _ % $ // Latex special characters (don't substitute \ so we can insert math with \( \) )
	foreach char in `specialchars' {
		local substitute `substitute' `char' $BACKSLASH`char'
	}
	local substitute `substitute' "\_cons " Constant
	local cmd esttab quipu* using "`filename'.tex"
	local tex_opt longtable booktabs substitute(`substitute')
	RunCMD `cmd', `tex_opt' `options'
end
program define BuildPDF
syntax, filename(string) latex_engine(string) VIEW [*]

	* PDF preface and epilogue
	qui findfile quipu-top.tex.ado
	local fn_top = r(fn)
	qui findfile quipu-bottom.tex.ado
	local fn_bottom = r(fn)


	* Substitute characters conflicting with latex
	local specialchars _ % $ // Latex special characters (don't substitute \ so we can insert math with \( \) )
	foreach char in `specialchars' {
		local substitute `substitute' `char' $BACKSLASH`char'
	}
	local substitute `substitute' "\_cons " Constant "..." "\ldots"

	local cmd esttab quipu* using "`filename'.tex"
	local tex_opt longtable booktabs substitute(`substitute')
	local pdf_options top(`fn_top') bottom(`fn_bottom')
	RunCMD `cmd', `tex_opt' `pdf_options' `options'

	local args latex_engine(`latex_engine') filename(`filename')
	cap erase "`filename'.log"
	cap erase "`filename'.aux"
	CompilePDF, `args'
	CompilePDF, `args' // longtable often requires a rerun
	di as text `"(output written to {stata "shell `filename'.pdf":`filename'.pdf})"'
	if ("`view'"!="") RunCMD shell `filename'.pdf
	cap erase "`filename'.log"
	cap erase "`filename'.aux"
end


// Input-Output
program define CompilePDF
	syntax, filename(string) latex_engine(string)
	
	* Get folder
	local tmp `filename'
	local left
	local dir
	while strpos("`tmp'", "/")>0 | strpos("`tmp'", "\")>0 {
		local dir `macval(dir)'`macval(left)' // if we run this at the end of the while, we will keep the /
		* We need -macval- to deal with the "\" in `dir' interfering with the `' in left
		gettoken left tmp : tmp, parse("/\")
	}

	tempfile stderr stdout
	cap erase "`filename'.pdf" // I don't want to BELIEVE there is no bug
	if ($quipu_verbose<=1) local quiet "-quiet"
	RunCMD shell `latex_engine' "`filename'.tex" -halt-on-error `quiet' -output-directory="`dir'" 2> "`stderr'" 1> "`stdout'" // -quiet
	if ($quipu_verbose>1) noi type "`stderr'"
	if ($quipu_verbose>1) di as text "{hline}"
	if ($quipu_verbose>1) noi type "`stdout'"
	cap conf file "`filename'.pdf"
	if _rc==601 {
		di as error "(pdf could not be created - run with -verbose(2)- to see details)"
		exit 601
	}
end
program define RunCMD
	if ($quipu_verbose>0) {
		di as text "[cmd] " as input `"`0'"'
	}
	`0'
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
	assert_msg `key_exists'==1, msg("metadata[`key'] does not exist") rc(510)
	mata: st_local("value", asarray(metadata, "`key'"))
	c_local `lcl' `"`value'"'
end
program define SetMetadata
	* [Syntax] SetMetadata key1.key2=value
	assert "`0'"!=""
	gettoken key 0: 0 , parse("=")
	gettoken equalsign value: 0 , parse("=")
	local key `key' // trim spaces
	local value `value' // trim spaces
	*di as error `"metadata[`key'] = <`value'>"'
	mata: asarray(metadata, "`key'", `"`value'"')
end


// Misc
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

	
// -------------------------------------------------------------------------------------------------
// Import metadata.txt (kinda-markdown-syntax with metadata for footnotes, etc.)
// -------------------------------------------------------------------------------------------------
mata:
mata set matastrict off

void read_metadata()
{
	external metadata
	fn = st_global("quipu_path") + "/" + "metadata.txt"
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
		printf("{txt}(%s key-value pairs added to quipu metadata)\n", strofreal(i))
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

