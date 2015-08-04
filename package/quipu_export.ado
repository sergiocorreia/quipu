// -------------------------------------------------------------------------------------------------
// QUIPU_EXPORT - Exports the Estimation Tables
// -------------------------------------------------------------------------------------------------
/// SYNTAX
/// quipu export [using] [if] , as(..) [quipu_options] [esttab_options] [estout_options]
program define quipu_export
	qui which yaml.ado

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
	
	Initialize, ext(`ext') metadata(`metadata') `verbose' // Define globals and mata objects (including the metadata)
	Use `ifcond' // Load selected estimates
	LoadEstimates `header', scalebaseline(`scalebaseline') // indicate(`indicate') // Loads estimates and sort them in the correct order
	BuildPrehead, ext(`ext') colformat(`colformat') title(`title') label(`label') ifcond(`ifcond') orientation(`orientation') size(`size') varwidth(`varwidth') colsep(`colsep')
	BuildHeader `header', headerhide(`headerhide') ext(`ext') fmt(`fmt') // Build header and saves it in $quipu_header (passed to posthead)
	BuildStats `stats', ext(`ext') scalebaseline(`scalebaseline')
	BuildPrefoot, ext(`ext') // This creates YES/NO for indicators, so run this before clearing the data!
	BuildVCENote, vcenote(`vcenote') // This clears the data!
	clear // Do after (BuildHeader, BuildStats). Do before (BuildRHS)
	BuildRHS, ext(`ext') rename(`rename') drop(`drop') indicate(`indicate') varwidth(`varwidth') // $quipu_rhsoptions -> rename() drop() varlabels() order()
	BuildFootnotes, ext(`ext') notes(`notes') stars(`stars') // Updates $quipu_footnotes
	BuildPostfoot, ext(`ext') orientation(`orientation') size(`size') `pagebreak'  // Run *AFTER* building $quipu_footnotes
	BuildPosthead, ext(`ext')

	if ($quipu_verbose>1) local noisily noisily
	local prepost prehead(`"$quipu_prehead"') posthead(`"${quipu_header}${quipu_posthead}"') prefoot(`"$quipu_prefoot"') postfoot(`"$quipu_postfoot"')
	
	yaml local fe_labels=metadata.misc.fe_labels
	estfe quipu*, labels(`fe_labels') // no need to do -estfe quipu* , restore
	local indicate_fe `"`r(indicate_fe)'"'

	* Defaults
	local yes "Yes"
	local no "No"
	* Retrieve metadata
	cap yaml local yes=metadata.misc.indicate_yes
	cap yaml local no=metadata.misc.indicate_no
	* Add \text{} if needed
	if ("`ext'"!="html") local yes \multicolumn{1}{c}{`yes'}
	if ("`ext'"!="html") local no \multicolumn{1}{c}{`no'}

	if ("`varwidth'"!="") {
		local lower_prefix	"\VarLabel{`varwidth'}{"
		local lower_suffix	"}"
	}
	foreach part in `indicate' `indicate_fe' {
		local part : subinstr local part "=" "`lower_suffix'="
		local part `lower_prefix'`part'
		local fixed_indicate `"`fixed_indicate' "`part'""'
	}
	
	local base_opt replace `noisily' $quipu_rhsoptions $quipu_starlevels mlabels(none) nonumbers `cellformat' ${quipu_stats} `prepost' indicate(`fixed_indicate', labels(`yes' `no'))

	if ("`ext'"=="html") BuildHTML, filename(`filename') `view' `base_opt' `options' // style(html)
	if ("`ext'"=="pdf") BuildPDF, filename(`filename') engine(`engine') `view' `base_opt' `options'
	if ("`ext'"=="tex") BuildTEX, filename(`filename') `base_opt' `options'  // Run after PDF so it overwrites the .tex file

	Cleanup
end
program define Parse
	syntax [anything(everything)] , ///
		[VERBOSE(integer 0) /// 0=No Logging, 2=Log Everything
		VIEW /// Open the PDF/HTML viewer  at the end?
		ENGINE(string) /// xelatex (smaller pdfs, better fonts) or pdflatex (faster)
		SIZE(integer 5) ORIENTation(string) PAGEBREAK /// More PDF options
		COLFORMAT(string) /// Alternatives include 1) D{.}{.}{-1} with dcolumn 2) c 3) p{2cm} 4) C{2cm} with array + a custom cmd
		COLSEP(string) ///
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
		Indicate(string asis) ///
		Order(string asis) VARLabels(string asis) KEEP(string asis) /// ESTOUT TRAP OPTIONS: Will be silently ignored!
		VARWIDTH(string) ///
		SCALEBASELINE(real 1.0) ///
		] [*]
	* Note: Remember to update any changes here before the bottom c_local!

	* Parse -indicate- vs -indicate()-
	if (`"`indicate'"'=="") {
		local 0 , `options'
		syntax, [Indicate] [*]
		if ("`indicate'"!="") local indicate _cons
		* HACK: _all and _cons are reserved names; in this case _all = _cons + all i.xyz variables
	}

	assert_msg inlist("`verbose'", "0", "1", "2"), msg("Wrong verbose level (needs to be 0, 1 or 2)")
	global quipu_verbose `verbose'

	* Syntax can't handle -if- ot in dataset
	* Will save 3 locals: filename (full path+fn WITHOUT THE EXT!), extension, and ifcond
	ParseUsingIf `anything'

	ParseHeader `header' // injects `header' and `headerhide'

	if ("`colformat'"=="") local colformat "S" // C{2cm} c S
	if ("`engine'"=="") local engine "xelatex"
	assert_msg inlist("`engine'", "xelatex", "pdflatex"), msg("invalid latex engine: `engine'")
	if ("`orientation'"=="") local orientation "portrait"
	assert_msg inlist("`orientation'", "landscape", "portrait", "inline"), msg("invalid page orientation (needs to be landscape, portrait or inline (=float portrait))")
	assert_msg inrange(`size', 1, 10), msg("invalid table size (needs to be an integer between 1 and 10)")
	if ("`stars'"=="") local stars "0.10 0.05 0.01" // 0.05 0.01 ??
	foreach cutoff of local stars {
		assert_msg real("`cutoff'")<. , msg("invalid cutoff: `cutoff' (not a number)")
		assert_msg inrange(`cutoff', 0.0, 1.0) , msg("invalid cutoff: `cutoff' (outside [0-1])")
	}
	if ("`cellformat'"=="") local cellformat "b(a3) se(a3)"
	
	* Inject values into caller (Export.ado)
	local names filename ext ifcond tex pdf html view engine orientation size pagebreak ///
		colformat colsep notes stars vcenote title label stats ///
		rename drop indicate header headerhide cellformat metadata varwidth options scalebaseline
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
			* Extract the extension
			local ext_match = regexm(`"`filename'"', "\.([a-zA-Z0-9_]+)$")
			assert_msg `ext_match', msg(`"quipu export: filename has no file extension (`filename')"')
			local ext = lower(regexs(1))
			assert_msg inlist("`ext'", "tex", "pdf", "html"), msg(`"quipu export: invalid file extension "`ext'", valid are tex, pdf, html"')
			local filename = substr(`"`filename'"', 1, strlen(`"`filename'"') - strlen("`ext'") - 1)

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
	c_local ext `ext'
	c_local ifcond   `ifcond'
end
program define ParseHeader
	syntax [anything(name=header equalok everything)] , [hide(string)]
	
	* Set default options
	if ("`header'"=="") local header depvar #
	local header : subinstr local header "#" "autonumeric", word
	local hide : subinstr local hide "#" "autonumeric", word

	local hide_only : list hide - header
	assert_msg "`hide_only'"=="", msg("error in header() suboption hide(..): `hide_only' not in `header'")
	c_local header `header'
	c_local headerhide `hide'
end
program define Initialize
	syntax, EXTension(string) [METAdata(string asis)]

	global TAB "`=char(9)'"
	global ENTER "`=char(13)'"
	global BACKSLASH "`=char(92)'"
	
	* Load metadata
	if ($quipu_verbose>1) di as text "(loading metadata)"
	if ($quipu_verbose>1) local verbose verbose
	local fn "${quipu_path}/metadata.yaml"
	yaml read metadata using "`fn'" , `verbose'

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
	if ("`extension'"=="html") {
		mata: symbols = "&dagger; &sect; &para; &Dagger; 1 2 3 4 5 6 7 8 9"
	}
	else {
		mata: symbols = "\textdagger \textsection \textparagraph \textdaggerdbl 1 2 3 4 5 6 7 8 9"
	}
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
	global absorbed
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
program define LoadEstimates, eclass
syntax [anything(name=header equalok everything)] , ///
	[indicate(string)] ///  [Fmt(string asis)]
	[scalebaseline(real 1.0)]

	assert `scalebaseline'>0

	* Load estimates in the order set by varlist.dta (wrt depvar)
	rename depvar varname
	qui merge m:1 varname using "${quipu_path}/varlist", keep(master match) keepusing(sort_depvar) nogen nolabel nonotes
	rename varname depvar
	assert "${indepvars}"=="" // bugbug drop

	* "#" will be ignored when sorting
	local exclude autonumeric
	local header : list header - exclude

	* Variables that we need to construct from the estimates
	qui ds
	local existing_variables = r(varlist)
	local newvars : list header - existing_variables
	foreach var of local newvars {
		qui gen `var' = ""
	}
	forv i=1/`c(N)' {
		
		local fn = path[`i'] +"/"+filename[`i']
		local num_estimate = num_estimate[`i']
		estimates use "`fn'", number(`num_estimate')

		foreach var of local newvars {
			qui replace `var' = "`e(`var')'" in `i'
		}
		estimates drop .
	}

	* Sort the dataset (columns of table will reflect that)
	local groups
	foreach var of local header {
		if ("`var'"!="depvar") qui gen byte sort_`var' = .
		cap yaml local cats=metadata.header.sort.`var'
		assert inlist(_rc, 0, 510)
		if (!_rc) {
			local i 0
			while (`"`cats'"'!="") {
				gettoken cat cats : cats
				local is_string = strpos("`: type `var''", "str")==1
				if (`is_string') {
					qui replace sort_`var' = `++i' if `var'=="`cat'"
				}
				else {
					qui replace sort_`var' = `++i' if `var'==`cat'
				}
			}
		}
		bys `groups' sort_`var' `var': gen byte _group_`var' = _n==1
		qui replace _group_`var' = sum(_group_`var')
		local groups `groups' _group_`var'
	}

	sort `groups' time
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
		local num_estimate = num_estimate[`i']
		estimates use "`fn'", number(`num_estimate')

		* Inject stuff into e()
		if ("`e(exexog_ct)'"!="" & "`e(endog_ct)'"!="") StockYogo // Load Stock Yogo crit values at 20%

		cap conf matrix e(summarize)
		if !c(rc) & "`e(baseline)'"=="" {
			tempname summarize
			matrix `summarize' = e(summarize)
			cap matrix `summarize' = `summarize'["mean", "`e(depvar)'"] // row -mean- may not exist
			if (!c(rc)) ereturn scalar baseline = `summarize'[1,1] * `scalebaseline'
		}
		
		estimates title: "`fn'"
		GetVars, indicate(`indicate') pos(`i') // This injects `indepvars' and creates/replaces variables
		local indepvarlist : list indepvarlist | indepvars
		estimates store quipu`i', nocopy
	}
	global indepvars `indepvarlist'
	global absorb
end

* Get -indepvars- and base names for absorbed variables
program define GetVars
syntax, pos(integer) [indicate(string)]
	
	local vars : colnames e(b)

	if ("`indicate'"=="") {
		* Remove omitted
		foreach var of local vars {
			local is_omitted = regexm("`var'", "o\.")
			if (!`is_omitted') {
				local includedvars `includedvars' `var'
			}
		}
		c_local indepvars `includedvars'
		exit
	}

	* Default (always check for these)
	if ("`e(cmd)'"=="xtreg" & "`e(model)'"=="fe") local absorbed `absorbed' `e(ivar)' // xtreg,fe
	if ("`e(absvar)'"!="") local absorbed `absorbed' `e(absvar)' // areg
	if ("`e(absvars)'"!="") local absorbed `absorbed' `e(absvars)' // reghdfe

	* Check for patterns (id_*) and factor variables (123bn.id)
	if ("`indicate'"!="_cons") {
		local all "_all"
		local match_all : list all in indicate

		* This weird loop creates locals -basepatterns- -fn- (which evals a fn!) and -dotted- (which is kinda unnecesary)
		local i 0
		foreach pat of local indicate {
			if (strpos("`pat'", "*") | strpos("`pat'", "?")) {
				local basepatterns `patterns' `pat'
				* Too bad if a var matches more than one pattern
				local fn `macval(fn)' + `++i' * strmatch("\`var'", "`pat'")
			}
			else {
				local dotted `dotted' `pat'
			}
		}

		* Store non-indicator vars in `indepvars' and the base vars of the indicator ones in `absorbed'
		foreach var of local vars {

			local is_omitted = regexm("`var'", "o\.")
			if (`is_omitted') continue

			local is_indicator 0
			local basevar `var'
			while (regexm("`basevar'", "^[0-9]+[bn]*\.")) {
				local is_indicator 1
				local basevar = regexr("`basevar'", "[0-9]+[bn]*\.", "i.")
			}

			* Only evaluate this fn when needed, b/c it's slow
			local pattern_pos 0
			if (!`is_indicator' & "`basepatterns'"!="") {
				local pattern_pos = `fn'
				assert `pattern_pos'>=0 & `pattern_pos'<.
			}

			if (`is_indicator' & `match_all') {
				if ("`basevar'"!="`lastbasevar'") local absorbed `absorbed' `basevar'
				local lastbasevar `basevar'
			}
			else if (`is_indicator' & `: list basevar in dotted') {
				if ("`basevar'"!="`lastbasevar'") local absorbed `absorbed' `basevar'
				local lastbasevar `basevar'
			}
			else if (`pattern_pos') {
				local basevar : word `pattern_pos' of `basepatterns'
				if ("`basevar'"!="`lastbasevar'") local absorbed `absorbed' `basevar'
				local lastbasevar `basevar'
			}
			else {
				local indepvars `indepvars' `var'
			}
		}
	}

	c_local indepvars `indepvars'

	local absorbed : list uniq absorbed
	foreach var of local absorbed {
		* Remove Dots Hashes Question marks and Stars
		local fixedvar `var'
		local fixedvar = subinstr(subinstr("`fixedvar'", "?","_QQ_", .), "*","_SS_", .) // Pattern
		local fixedvar = subinstr(subinstr("`fixedvar'", ".","_DD_", .), "#","_HH_", .) // Factor variables

		cap gen byte ABSORBED_`fixedvar' = 0
		if (!_rc) la var ABSORBED_`fixedvar' "`var'"
		qui replace ABSORBED_`fixedvar' = 1 in `pos'
	}
end

* Problem: need to load estimates to use this..
program define StockYogo, eclass
	* BUG: Only works with up to 2 endogvars
	* Piggybacks on ivreg2 and estadd!
	tempname stats cv
	mata: s_cdsy("`stats'", 5) // 2=10% bias, 3=20% bias, ... 5=10% size  7=20^ size
	local k2 = e(exexog_ct)
	local nendog = e(endog_ct)
	scalar `cv' = `stats'[`k2', `nendog']
	ereturn scalar stock_yogo = `cv'
	*di e(stock_yogo)
end


// Building Blocks
program define BuildPrehead
syntax, EXTension(string) [*]
	if ("`extension'"=="html") {
		BuildPreheadHTML, `options'
	}
	else {
		BuildPreheadTEX, `options'
	}
end
program define BuildPreheadHTML
syntax, colformat(string) size(integer) [title(string) label(string) ifcond(string asis)] ///
	orientation(string) [varwidth(string) colsep(string)] // THESE WILL BE IGNORED
	local hr = 32 * " "

	global quipu_prehead ///
		`"<!-- `hr' QUIPU - Stata Regression `hr'"' ///
		`"  - Criteria: `ifcond'"' ///
		`"  - Estimates: ${quipu_path}"' ///
		"-->" ///
		`"  <table class="estimates" name="`label'">"' ///
		`"  <caption>`title'</caption>"'
end
program define BuildPreheadTEX
syntax, orientation(string) [varwidth(string)] [*]
	
	if ("`varwidth'"!="") {
		* The [t] aligns the top of the varwidth block with the rest of the row
		local varlist_layout  "@{\begin{varwidth}[t]{`varwidth'}\narrowragged} l @{\end{varwidth}}"
	}
	else {
		local varlist_layout "l"
	}

	BuildPreheadTEX_`orientation', varlist_layout(`varlist_layout') `options'
	*global quipu_prehead : subinstr global quipu_prehead "#" "\#", all
end
program define BuildPreheadTEX_landscape
syntax, colformat(string) size(integer) varlist_layout(string) ///
	[title(string) label(string) ifcond(string asis)] ///
	[colsep(string)]

	local hr = 32 * "*"
    local size_names tiny scriptsize footnotesize small normalsize large Large LARGE huge Huge
    local size_colseps 04 11 11 30 30 30 30 30 30 30 // 04 = 0.04cm

	local bottom = cond(`size'<=2, 2, 3)
    local size_name : word `size' of `size_names'
    local size_colseps : word `size' of `size_colseps' // set default

    if ("`colsep'"=="") local colsep 0.`size_colseps'cm

	global quipu_prehead ///
		`"\newgeometry{bottom=`bottom'cm}$ENTER\begin{landscape}$ENTER\setlength\LTcapwidth{\linewidth}"' ///
		`"$BACKSLASH`size_name'"' ///
		`"\tabcolsep=`colsep'"' ///
		`"\centering"' ///
		`"\captionsetup{singlelinecheck=off,labelfont=bf,labelsep=newline,font=bf,justification=justified}"' /// Different line for table number and table title
		`"\begin{ThreePartTable}"' ///
		`"\renewcommand{\TPTminimum}{\linewidth}"' ///
		`"$TAB\begin{TableNotes}$ENTER$TAB$TAB\${quipu_footnotes}$ENTER$TAB\end{TableNotes}"' ///
		`"$TAB\begin{longtable}{`varlist_layout' *{@M}{`colformat'}}"' /// {}  {c} {p{1cm}}
		`"$TAB\caption{`title'}\label{table:`label'} \\"' ///
		`"$TAB\toprule\endfirsthead"' ///
		`"$TAB\midrule\endhead"' ///
		`"$TAB\midrule\endfoot"' ///
		`"$TAB\${quipu_insertnote}\endlastfoot"'
end
program define BuildPreheadTEX_portrait
syntax, colformat(string) size(integer) varlist_layout(string) ///
	[title(string) label(string) ifcond(string asis)] ///
	colsep(string)

	local hr = 32 * "*"
    local size_names tiny scriptsize footnotesize small normalsize large Large LARGE huge Huge
    local size_colseps 04 11 11 30 30 30 30 30 30 30 // 04 = 0.04cm

	local bottom = cond(`size'<=2, 2, 3)
    local size_name : word `size' of `size_names'
    local size_colseps : word `size' of `size_colseps'

    if ("`colsep'"=="") local colsep 0.`size_colseps'cm

	global quipu_prehead ///
		`"{"' ///
		`"$BACKSLASH`size_name'"' ///
		`"\tabcolsep=`colsep'"' ///
		`"\centering"' /// Prevent centering captions that fit in single lines; don't put it in the preamble b/c that makes normal tables look ugly
		`"\captionsetup{singlelinecheck=on,labelfont=bf,labelsep=colon,font=bf,justification=centering}"' ///
		`"\begin{ThreePartTable}"' ///
		`"\renewcommand{\TPTminimum}{0.9\textwidth}"' /// textwidth vs linewidth
		`"$TAB\begin{TableNotes}$ENTER$TAB$TAB\${quipu_footnotes}$ENTER$TAB\end{TableNotes}"' ///
		`"$TAB\begin{longtable}{`varlist_layout' *{@M}{`colformat'}}"' /// {}  {c} {p{1cm}}
		`"$TAB\caption{`title'}\label{table:`label'} \\"' ///
		`"$TAB\toprule\endfirsthead"' ///
		`"$TAB\midrule\endhead"' ///
		`"$TAB\midrule\endfoot"' ///
		`"$TAB\${quipu_insertnote}\endlastfoot"'
end
program define BuildPreheadTEX_inline
syntax, colformat(string) size(integer) [title(string) label(string) ifcond(string asis)] ///
	colsep(string)

	local hr = 32 * "*"
    local size_names tiny scriptsize footnotesize small normalsize large Large LARGE huge Huge
    local size_colseps 04 11 11 30 30 30 30 30 30 30 // 04 = 0.04cm

	local bottom = cond(`size'<=2, 2, 3)
    local size_name : word `size' of `size_names'
    local size_colseps : word `size' of `size_colseps'

    if ("`colsep'"=="") local colsep 0.`size_colseps'cm

	global quipu_prehead ///
		`"$ENTER\begin{comment}"' ///
		`"$TAB`hr' QUIPU - Stata Regression `hr'"' ///
		`"$TAB - Criteria: `ifcond'"' ///
		`"$TAB - Estimates: ${quipu_path}"' ///
		`"\end{comment}"' ///
		`"{"' ///
		`"$BACKSLASH`size_name'"' ///
		`"\begin{table}[!thbp]"' ///
		`"\tabcolsep=`colsep'"' ///
		`"\centering"' /// Prevent centering captions that fit in single lines; don't put it in the preamble b/c that makes normal tables look ugly
		`"\captionsetup{singlelinecheck=on,labelfont=bf,labelsep=colon,font=bf,justification=centering}"' ///
		`"\begin{ThreePartTable}"' ///
		`"\renewcommand{\TPTminimum}{0.9\textwidth}"' /// textwidth vs linewidth
		`"$TAB\caption{`title'}\label{table:`label'}"' ///
		`"$TAB\begin{tabular}{`varlist_layout' *{@M}{`colformat'}}"' /// {}  {c} {p{1cm}}
		`"$TAB\toprule"'
end
program define BuildHeader
syntax [anything(name=header equalok everything)], EXTension(string) [Fmt(string asis)] [HEADERHIDE(string)]

	* Set replacement locals
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

	if ("`extension'"=="html") {
		
		local cell_start `"      <th colspan="\`n'">"'
		local cell_end "</th>${ENTER}"
		local cell_sep ""
		local cell_line // "\cmidrule(lr){\`start_col'-\`end_col'} "

		local row_start "    <tr>${ENTER}"
		local row_end `"    </tr>${ENTER}"'
		local row_sep
		
		local header_start "  <thead>${ENTER}"
		local header_end "  </thead>${ENTER}"
		local offset 1 // First cell in row is usually empty
		local topleft "      <th></th>${ENTER}"
		local topleft_auto `"`topleft'"'

		local linestart ""
		local lineend ""
	}
	else {
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
		local topleft "\multicolumn{1}{l}{\`header_label'} & "
		local topleft_auto "\multicolumn{1}{c}{} & "

		local linestart "$TAB"
		local lineend "${ENTER}"
	}

	local ans "`header_start'" // Will contain the header string
	local numrow 0
	foreach cat of local header {

		local hidden : list cat in headerhide
		if (`hidden') continue

		local ++numrow
		local line "`linestart'"
		local numcell 0
		if ("`cat'"=="autonumeric") {
			local row `"`row_start'`topleft_auto'"'
			forval i = 1/`c(N)' {
				local cell = subinstr("`template_`cat''", "@", "`i'", .)
				local n 1
				local sep = cond(`i'>1, "`cell_sep'", "")
				local row `"`row'`sep'`cell_start'`cell'`cell_end'"'
			}
			local sep = cond(`numrow'>1, "`row_sep'", "")
			local ans `"`ans'`sep'`row'`row_end'"'
		}
		else {

			qui su span_`cat'
			local is_group = (r(max)>1)
			assert inlist(`is_group', 0, 1)

			local header_label
			cap yaml local header_label=metadata.header.label.`cat'

			local row `"`row_start'`topleft'"' // TODO: Allow a header instead of empty or `cat'
			forval i = 1/`c(N)' {
				local inactive = inactive_`cat'[`i']
				if (!`inactive') {
					local ++numcell
					
					if ("`cat'"=="depvar") {
						local cell = varlabel[`i']	
						local footnote = footnote[`i']
						AddFootnote, ext(`extension') footnote(`footnote')
						local cell "`cell'`r(symbolcell)'"
					}
					else {
						local cell = `cat'[`i']
						cap yaml local cell=metadata.groups.`cat'.`cell' // Will abort if label not found
						local cell = subinstr("`template_`cat''", "@", "`cell'", .)
					}

					local n = span_`cat'[`i']
					local start_col = `offset' + `i'
					local end_col = `start_col' + `n' - 1
					local sep = cond(`numcell'>1, "`cell_sep'", "")
					
					if ("`extension'"=="html" & `is_group') {
						local row `"`row'`sep'`cell_start'<p class="underline">`cell'</p>`cell_end'"'
					}
					else {
						local row `"`row'`sep'`cell_start'`cell'`cell_end'"'
						local line `line'`cell_line'
					}
				}
			}
			local sep = cond(`numrow'>1, "`row_sep'", "")
			
			if ("`extension'"!="html" & `is_group') {
				local ans "`ans'`sep'`row'`row_end'`line'`lineend'"
			}
			else {
				local ans "`ans'`sep'`row'`row_end'"
			}
		}
	}
	local ans "`ans'`header_end'"
	global quipu_header `"`ans'"'
	*global quipu_header : subinstr global quipu_header "#" "\#", all
	drop varlabel footnote
end
program define BuildPosthead
syntax, EXTension(string) [*]
	if ("`extension'"=="html") {
		BuildPostheadHTML, `options'
	}
	else {
		BuildPostheadTEX, `options'
	}
end
program define BuildPostheadHTML
syntax, [*]
	global quipu_posthead `"  <tbody>$ENTER"'
end
program define BuildPostheadTEX
syntax, [*]
	global quipu_posthead "  $ENTER"
end
program define BuildPrefoot
	syntax, EXTension(string)

	if ("`extension'"=="html") {
		global quipu_prefoot "  </tbody>$ENTER$ENTER"

		local cell_start `"      <td>"'
		local cell_end "</td>${ENTER}"
		local cell_sep ""
		local cell_line

		local row_start "    <tr>${ENTER}"
		local row_end `"    </tr>${ENTER}"'
		local row_sep

		local region_start `"  <tbody class="absvars">"'
		local region_end `"  </tbody>$ENTER$ENTER"'
	}
	else {
		global quipu_prefoot "$TAB\midrule"

		local cell_start "\multicolumn{\`n'}{c}{"
		local cell_end "}"
		local cell_sep " & "
		local cell_line "\cmidrule(lr){\`start_col'-\`end_col'} "
		local row_start "${TAB}"
		local row_end "$TAB${BACKSLASH}${BACKSLASH}${ENTER}"
		local row_sep ""

		local region_start ""
		local region_end "$TAB\midrule"
	}

	*** Add rows with FEs Yes/No
	**cap ds ABSORBED_*
	**if (!_rc) {
	**	
	**	yaml local yes=metadata.misc.indicate_yes
	**	yaml local no=metadata.misc.indicate_no
	**
	**	local absvars = r(varlist)
	**	local region "`region_start'"
	**	local numrow 0
	**	foreach absvar of local absvars {
	**		local ++numrow
	**		local label : var label `absvar'
	**		local row `"`cell_start'`label'`cell_end'"'
	**		forval i = 1/`c(N)' {
	**			local cell = cond(`absvar'[`i'], "`yes'", "`no'")
	**			local row `"`row'`cell_sep'`cell_start'`cell'`cell_end'"'
	**		}
	**		local sep = cond(`numrow'>1, "`row_sep'", "")
	**		local region `"`region'`sep'`row'`row_end'"'
	**	}
	**	local region `"`region'`region_end'"'
	**}

	* Add what goes after the FEs
	if ("`extension'"=="html") {
		global quipu_prefoot `"${quipu_prefoot}`region'  <tfoot>$ENTER"'
	}
	else {
		global quipu_prefoot `"${quipu_prefoot}`region'"'
	}

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
syntax, EXTension(string) [rename(string asis) drop(string asis)] ///
	[indicate(string asis)] /// Don't add labels to indicate
	[varwidth(string)]

	* NOTE: -estout- requires that after a rename, all the options MUST USE THE NEW NAME
	* i.e. if I rename(price Precio), then when calling -esttab- I need to include keep(Precio)
	* (and so oon for varlabels, order, etc.)

	local indepvars $indepvars
	local N : word count `indepvars'
	qui set obs `N'
	qui gen varname =""

	* Fill -varname- and merge to get variable labels
	forv i=1/`N' {
		gettoken indepvar indepvars : indepvars
		qui replace varname = "`indepvar'" in `i'
	}
	clonevar expanded_name = varname
	qui replace varname = substr(varname, strpos(varname, ".")+1, .) // bugbug (need to generalize to e.g. i.x#i.y#L.z)
	qui merge m:1 varname using "${quipu_path}/varlist", keep(master match) ///
		nogen nolabel nonotes keepusing(varlabel footnote sort_indepvar sort_depvar)
	gen stub = substr(expanded_name, 1, strpos(expanded_name, "."))
	qui replace varlabel = stub + varlabel if varlabel!=""
	drop varname stub
	rename expanded_name varname

	* Drop variables
	if (`"`drop'"'!="") {
		gen byte dropit = 0
		while (`"`drop'"'!="") {
			gettoken s1 drop : drop
			qui replace dropit = 1 if regexm(varname, "^`s1'$")
		}
		if ($quipu_verbose>0) {
			qui levelsof varname if dropit, local(rhsdrop) clean
			di as text "(dropping variables: " as result "`rhsdrop'" as text ")"
		}
		qui drop if dropit
		drop dropit
	}

	* Rename variables. Note: Can't use estout for simple renames b/c it messes up the varlabels
	if (`"`rename'"'!="") {
		qui gen original = varname
		while (`"`rename'"'!="") {
			gettoken s1 rename : rename
			gettoken s2 rename : rename
			assert_msg `"`s2'"'!="", msg("rename() must have an even number of strings")
			local ss2 `" "`s2'" "'
			if (strpos(`"`ss2'"', "[")>1) {
				forval i = 1/10 {
					local ss2 = subinstr(`"`ss2'"', "[`i']", `"" + regexs(`i') + ""', .)
				}
			}
			qui replace varname = `ss2' if regexm(varname, "^`s1'$")
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

	* Set varlabel option
	* BUGBUG, put lags later
	bys sort_indepvar: gen byte lag = real(regexs(1)) if regexm(varname, "^L([0-9]+)\.")
	qui replace lag = 0 if missing(lag)
	sort sort_indepvar // orders RHS, and ensures footnote daggers will be in order
	sort sort_indepvar lag
	drop lag

	gen byte is_indicate = 0
	while (`"`indicate'"'!="") {
		gettoken part indicate : indicate
		gettoken part_label part_pattern : part , parse("=")
		gettoken eqsign part_pattern : part_pattern , parse("=")
		
		* Need to allow "stub1* stub*" syntax like -estout-
		foreach pat of local part_pattern { 
			assert "`pat'"!=""
			replace is_indicate = 1 if strmatch(varname, "`pat'")
		}
	}

	if ("`varwidth'"!="") {
		local prefix	"\FlatVarLabel{`varwidth'}{"
		local suffix	"}"
	}

	forv i=1/`c(N)' {
		local varname = varname[`i']
		local footnote = footnote[`i']
		local varlabel = varlabel[`i']
		local is_indicate = is_indicate[`i']

		if (`is_indicate') continue

		* If both footnotes and varlabels have nothing, then we don't need to relabel the var!
		* This is critical if we have a regr. with 1000s of dummies
		* But then we don't want to print that!
		if (1) {
		*if ("`varlabel'"!="" | "`footnote'"!="") {
			* We need *something* as varlabel, to put next to the footnote dagger
			if ("`varlabel'"=="") local varlabel `"`varname'"'
			AddFootnote, ext(`extension') footnote(`footnote')
			local varlabels `"`varlabels' `varname' "`prefix'`varlabel'`r(symbolcell)'`suffix'" "'
		}
		local order `order' `varname'
	}

	* Fill contents of keep (must be done after the renames are made)
	* Also after indicate
	qui levelsof varname if !is_indicate, local(rhskeep) clean

	* Groups +-+-
	* ...

	drop _all // BUGBUG: clear?

	if ("`varwidth'"!="") {
		* Need to subtract a bit or else it will clash with the next column
		local varlabels `"`varlabels' _cons Constant "' // , prefix("\smash{\begin{minipage}[t]{`varwidth'-1mm}\hangindent=0.2cm") suffix("\end{minipage}} ") "'
	}
	else {
		local varlabels `"`varlabels' _cons Constant , end("" "") nolast"'
	}
	
	*local varlabels `"`varlabels' _cons Constant , prefix("\multirow{2}{*}[2em]{\vfil \begin{minipage}[t]{5cm}") suffix("\end{minipage}} ") "'
	// end("" "") nolast
	*local varlabels `"`varlabels' _cons Constant , prefix("\multirow{2}{*}{ \begin{minipage}[t]{5cm}{") suffix("}\end{minipage}}") "' // end("" "") nolast
	* \rule[-.3\baselineskip]{2mm}{2.3\baselineskip}

	* Set global option
	assert_msg "`rhskeep'"!="", msg("No RHS variables kept!")
	global quipu_rhsoptions varlabels(`varlabels') order(`order') rename(`rhsrename')
	
	*keep(`rhskeep') // bugs with keep (messes with indicate, refcat, etc.)

end
program define BuildStats
syntax [anything(name=stats equalok everything)],  EXTension(string) [scalebaseline(real 1.0)]
	// [Fmt(string) Labels(string asis)]

	local DEFAULT_STATS_all N
	local DEFAULT_STATS_ols r2 r2_a
	local DEFAULT_STATS_iv underid weakid overid // idp widstat jp
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
	local labels_F			"F Statistic"
	local labels_r2		"\(R^2\)"
	local labels_r2_a		"Adjusted \(R^2\)"
	local labels_idp		"Underid. P-val. (KP LM)"
	local labels_widstat	"Weak id. F-stat (KP Wald)"
	local labels_jp		"Overid. P-val (Hansen J)"
	
	local labels_baseline "Mean of Dependent Variable"
	if (`scalebaseline'!=1) local labels_baseline "`labels_baseline' \((\times `scalebaseline')\)"

	local labels_underid_1 "Underidentification test"
	local labels_underid_2 "\enskip \(p \, \) value"

	local labels_weakid_1 "Weak identification F stat."
	local labels_weakid_2 "\enskip 10% maximal IV size"

	local labels_overid_1 "Overidentification J stat."
	local labels_overid_2 "\enskip \(p \, \) value"

	local fmt_N			%12.0gc
	local fmt_N_clust	%12.0gc
	local fmt_df_a		%12.0gc
	local fmt_r2		%6.3f
	local fmt_r2_a		%6.3f
	*local fmt_idp		%6.3fc
	*local fmt_widstat	%6.2fc
	*local fmt_jp		%6.3fc

	local fmt_id0		%2.0f // Number of dof
	local fmt_id1		%5.1f // The Fstats or Chi stats
	local fmt_id2		%5.3f // The p-values

	local fmt_baseline	%6.4g

	local DEFAULT_FORMAT a3

	* Underidentification test (Kleibergen-Paap rk LM statistic) = idstat iddf idp
	* Weak identification test (Kleibergen-Paap rk Wald F statistic) = e(widstat) // stock-yogo?
	* Hansen J statistic (overidentification test of all instruments) =  e(jp)  e(jdf)  e(j)
		// The joint null hypothesis is that the instruments are valid instruments
		// A rejection casts doubt on the validity of the instruments.

	* Parse received fmt and labels, to override defaults
	*foreach cat in fmt labels {
	*	local args `"``cat''"'
	*	while (`"`args'"'!="") {
	*		gettoken key args : args
	*		gettoken val args : args
	*		local `cat'_`key' `val'
	*	}
	*}

	* Parse stats
	local expanded_stats
	foreach stat of local stats {

		* Magical stats
		if inlist("`stat'", "overid", "weakid", "underid") {
			local statlabels `"`statlabels' "`labels_`stat'_1'" "`labels_`stat'_2'""'

			if ("`stat'"!="weakid") local statformats `"`statformats' `fmt_id0' `fmt_id1' `fmt_id2'"'
			if ("`stat'"=="weakid") local statformats `"`statformats' `fmt_id1' `fmt_id1'"'

			if ("`stat'"!="weakid") local exp "\(\chi^2(@){=}@\)"
			if ("`stat'"=="weakid") local exp "@"

			local layout = cond("`extension'"=="html", "`exp'", "\multicolumn{1}{r}{`exp'}")
			local layouts = `"`layouts' "`layout'""'
			local layout = cond("`extension'"=="html", "@", "\multicolumn{1}{r}{@}")
			local layouts = `"`layouts' "`layout'""'


			if ("`stat'"=="overid") local expanded_stats `expanded_stats' jdf  j jp
			if ("`stat'"=="underid") local expanded_stats `expanded_stats' iddf idstat idp
			if ("`stat'"=="weakid") local expanded_stats `expanded_stats' widstat stock_yogo
		}
		else {
			local expanded_stats `expanded_stats' `stat'
			local statlbl = cond(`"`labels_`stat''"'!="", `"`labels_`stat''"', "`stat'")
			local statfmt = cond(`"`fmt_`stat''"'!="", `"`fmt_`stat''"', "`DEFAULT_FORMAT'")
			local statlabels `"`statlabels' "`statlbl'""'
			local statformats `"`statformats' `statfmt'"'
			local layout = cond("`extension'"=="html", "@", "\multicolumn{1}{r}{@}")
			local layouts = `"`layouts' "`layout'""'
		}
	}

	global quipu_stats `"stats(`expanded_stats', fmt(`statformats') labels(`statlabels') layout(`layouts') )"'
end
program define BuildFootnotes
syntax, EXTension(string) stars(string) [notes(string)] [vcnote(string)]
	* BUGBUG: Autoset starnote and vcnote!!!

	local stars : list sort stars // Sort it
	local numstars : word count `stars'
	local starnote "Levels of significance: "
	forval i = `numstars'(-1)1 {
		local sign = "*" * `=`numstars'-`i'+1'
		local num : word `i' of `stars'
		local sep = cond(`i'>1, ", ", ".")
		local starnote "`starnote' `sign' \(p<`num'\)`sep'"
		local starlevels "`starlevels' \text{`sign'} `num'"
	}

	local sep1 = cond("${quipu_vcenote}"!="" & "`starnote'`notes'"!="", " ", "")
	local sep2 = cond("${quipu_vcenote}`starnote'"!="" & "`notes'"!="", " ", "")
	
	if ("`extension'"=="html") {
		local note "<em>Note.&mdash; </em>${quipu_vcenote}`sep1'`starnote'`sep2'`notes'"
		local summary "<summary>Regression notes</summary>"
		if (`"${quipu_footnotes}"'!="") {
			global quipu_footnotes `"<details open>${ENTER}`summary'${ENTER}  <dl class="estimates-notes">${ENTER}${quipu_footnotes}</dl>${ENTER}  <p class="estimates-notes">`note'</p></details>"'
		}
		else {
			global quipu_footnotes `"<details open>`note'</details>"'
		}
	}
	else {
		local note `"\Note{${quipu_vcenote}`sep1'`starnote'`sep2'`notes'}"'
		if (`"${quipu_footnotes}"'!="") {
			global quipu_footnotes `"${ENTER}`summary'${ENTER}${TAB}${ENTER}${quipu_footnotes}${ENTER}${TAB}`note'"'
		}
		else {
			global quipu_footnotes `"`note'"'
		}
	}



	* ThreePartTable fails w/out footnotes (although above we are kinda ensuring it will not be empty)
	if (`"$quipu_footnotes"'!="") global quipu_insertnote "\insertTableNotes"
	global quipu_starlevels starlevels(`starlevels')
end
program define BuildPostfoot
syntax, EXTension(string) [*]
	if ("`extension'"=="html") {
		BuildPostfootHTML, `options'
	}
	else {
		BuildPostfootTEX, `options'
	}
end
program define BuildPostfootHTML
syntax, [*]
	global quipu_postfoot `"  </tfoot>$ENTER$ENTER  </table>${quipu_footnotes}"'
end
program define BuildPostfootTEX
syntax, orientation(string) [*] [PAGEBREAK]
	* clearpage vs newpage http://tex.stackexchange.com/questions/45609/is-it-wrong-to-use-clearpage-instead-of-newpage
	local flush = cond("`pagebreak'"!="", "$ENTER\newpage", "")
	BuildPostfootTEX_`orientation', `options' flush(`flush')
end
program define BuildPostfootTEX_landscape
syntax, [flush(string)] size(integer) 
	global quipu_postfoot ///
		`"$TAB\bottomrule"' ///
		`"$TAB\end{longtable}"' ///
		`"\end{ThreePartTable}"' ///
		`"\vspace{-5pt}$ENTER\end{landscape}"' ///
		`"\restoregeometry`flush'"'
end
program define BuildPostfootTEX_portrait
syntax, [flush(string)] size(integer)
	global quipu_postfoot ///
		`"$TAB\bottomrule"' ///
		`"$TAB\end{longtable}"' ///
		`"\end{ThreePartTable}"' ///
		`"\vspace{15pt}$ENTER}"' ///
		`"\restoregeometry`flush'"'
end
program define BuildPostfootTEX_inline
syntax, [flush(string)] size(integer)
	global quipu_postfoot ///
		`"$TAB\bottomrule"' ///
		`"$TAB\end{tabular}"' ///
		`"$TAB\begin{TableNotes}$ENTER$TAB$TAB\${quipu_footnotes}$ENTER$TAB\end{TableNotes}"' ///
		`"\end{ThreePartTable}"' ///
		`"\end{table}"' /// `"\vspace{15pt}"' ///
		`"$ENTER}"'
end

	
* Receive a keyword, looks it up, and i) returns the symbol, ii) updates the global with the footnotes
program define AddFootnote, rclass
syntax,  EXTension(string) [FOOTNOTE(string)]

	if ("`footnote'"=="") {
		return local symbol ""
		exit
	}

	yaml local definition=metadata.footnotes.`footnote'
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
		if ("`extension'"=="html") {
			local thisnote `"    <dt>`symbol'</dt><dd>`definition'</dd>$ENTER"' 
		}
		else {
			local thisnote `"\item[`symbol'] `definition'${ENTER}${TAB}${TAB}"'
		}
		global quipu_footnotes `"${quipu_footnotes}`thisnote'"'
	}
	
	if ("`extension'"=="html") {
		local symbolcell `"<sup title="`definition'">`symbol'</sup>"'
	}
	else {
		local symbolcell "\tnote{`symbol'}"
	}
	return local symbolcell "`symbolcell'"
end
program define BuildHTML
syntax, filename(string) [VIEW] [*]

  * PDF preface and epilogue
  qui findfile quipu-top.html.ado
  local fn_top = r(fn)
  qui findfile quipu-bottom.html.ado
  local fn_bottom = r(fn)

  * Substitute characters conflicting with html
  local substitute \& & _cons Constant // < &lt; > &gt; & &amp; 

  local cmd esttab quipu* using "`filename'.html"
  local html_opt top(`fn_top') bottom(`fn_bottom') substitute(`substitute')
  RunCMD `cmd', `html_opt' `options'
  *di as text `"(output written to {stata "shell `filename'.html":`filename'.html})"'
  if ("`view'"!="") RunCMD shell `filename'.html
end


/* Primer on HTML Tables

# TLDR
Tables contain "table rows", that contain "table data" or "table headings"

# Template

<table ...>
	<tr>
		<td> ... </td>
		...
	</tr>
	...
</table>

# Attributes

## Borders

EG: border="1". But it's better to use CSS:

table, th, td {
    border: 1px solid black;
}

If you want the borders to collapse into one border, add CSS border-collapse:

table, th, td {
    border: 1px solid black;
    border-collapse: collapse;
}

## Padding
http://www.w3schools.com/html/tryit.asp?filename=tryhtml_table_cellpadding

## Add format just to headers:
th {
    text-align: left;
}

# BOrder spacing

Border spacing specifies the space between the cells.
table {
    border-spacing: 5px;
}

Note: If the table has collapsed borders, border-spacing has no effect.

## Multicolumn

EG: colspan="2" for each th/td ; and also rowspan 

## Caption
<table style="width:100%">
  <caption>Monthly savings</caption>
  ...

## Misc

Add ID to TABLE and set a special style: id="t01"
Then:
table#t01 {
    width: 100%; 
    background-color: #f1f1c1;
}

thead
tbody
tfoot
col
colgroup


*/
program define BuildTEX
syntax, filename(string) [*]

	* Substitute characters conflicting with latex
	local specialchars _ % $ // Latex special characters (don't substitute \ so we can insert math with \( \) )
	foreach char in `specialchars' {
		local substitute `substitute' `char' $BACKSLASH`char'
	}
	local substitute `substitute' "\_cons " Constant "..." "\ldots" "#" "\#"
	local cmd esttab quipu* using "`filename'.tex"
	local tex_opt longtable booktabs substitute(`substitute') modelwidth(1)
	* modelwdith(1) just makes the .tex smaller / easier to read
	RunCMD `cmd', `tex_opt' `options'
end
program define BuildPDF
syntax, filename(string) engine(string) [VIEW] [*]

	* PDF preface and epilogue
	qui findfile quipu-top.tex.ado
	local fn_top = r(fn)
	qui findfile quipu-bottom.tex.ado
	local fn_bottom = r(fn)


	* Substitute characters conflicting with latex
	local specialchars _ % $ # // Latex special characters (don't substitute \ so we can insert math with \( \) )
	foreach char in `specialchars' {
		local substitute `substitute' `char' $BACKSLASH`char'
	}
	local substitute `substitute' "\_cons " Constant "..." "\ldots" "#" "\#"

	local cmd esttab quipu* using "`filename'.tex"
	local tex_opt longtable booktabs substitute(`substitute') modelwidth(1)
	local pdf_options top(`fn_top') bottom(`fn_bottom')
	RunCMD `cmd', `tex_opt' `pdf_options' `options'

	local args engine(`engine') filename(`filename')
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
	syntax, filename(string) engine(string)
	
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
	RunCMD shell `engine' "`filename'.tex" -halt-on-error `quiet' -output-directory="`dir'" 2> "`stderr'" 1> "`stdout'" // -quiet
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

