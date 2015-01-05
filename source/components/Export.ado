capture program drop Export
program define Export
syntax [anything(everything)], as(string) /// tex pdf html
	[VERBOSE(integer 0)] /// 0=No Logging, 2=Log Everything
	[*] /// Passed to -ExportInner- and in turn to -esttab-
	
	* PARSE
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
	* Validate the as() strings
	foreach format in `as' {
		assert_msg inlist("`format'", "tex", "pdf", "html"), msg("<`format'> is an invalid output format")
	}

	* Set constants, globals, etc. (do just after parsing)
	Initialize, verbose(`verbose')

	* Load Estimates, sort them, and save $indepvars
	qui Use `ifcond'
	LoadEstimates

	* Export table
	ExportInner, filename(`filename') verbose(`verbose') `as' `options'
	
	* Cleanup
	Cleanup
end

capture program drop LoadEstimates
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

capture program drop ExportInner
program define ExportInner
syntax, VERBOSE(integer) ///
		[FILEname(string) /// Path+name of output file; ideally w/out extension
		HTML TEX PDF /// What are the desired output formats?
		VIEW /// Open the PDF viewer at the end?
		LATEX_engine(string) /// xelatex (smaller pdfs, better fonts) or pdflatex (faster)
		COLFORMAT(string) /// Alternatives include 1) D{.}{.}{-1} with dcolumn 2) c 3) p{2cm} 4) C{2cm} with array + a custom cmd
		NOTEs(string) /// Misc notes (i.e. everything besides the glossaries for symbols, stars, and vcv)
		VCVnote(string) /// Note regarding std. errors, in case default msg is not good enough
		title(string) ///
		label(string) /// Used in TeX labels
		] [*]

	if (`verbose'>0) global ESTDB_DEBUG 1
	if (`verbose'>1) local noisily noisily 
	if ("`latex_engine'"=="") local latex_engine "xelatex"
	assert_msg inlist("`latex_engine'", "xelatex", "pdflatex"), msg("invalid latex engine: `latex_engine'")

	local using = cond("`filename'"=="","", `"using "`filename'.tex""')
	local base_cmd esttab estdb* `using' , `noisily' ///
		varlabels(\`rhslabels') order(`rhsorder')
	local tex_options longtable booktabs ///
		prehead(\`prehead') posthead(\`posthead') prefoot(\`prefoot') postfoot(\`postfoot') substitute(\`substitute')

	* Substitute characters conflicting with latex
	local specialchars _ % $ // Latex special characters (don't substitute \ so we can insert math with \( \) )
	foreach char in `specialchars' {
		local substitute `substitute' `char' $BACKSLASH`char'
	}
	local substitute `substitute' "\_cons " \_cons

	* Format LHS Variables

	* Format RHS Variables
	GetRHSVarlabels // returns r(rhslabels) -> varlabels and r(rhsorder) -> order
	local rhslabels `"`r(rhslabels)'"'
	local rhsorder `"`r(rhsorder)'"'

	* Prepare text/code surrounding the table
	GetPrehead, colformat(`"`colformat'"') label(`"`label'"') title(`"`title'"')
	local prehead `"`r(prehead)'"'

	local line_subgroup // What was this?
	local posthead `line_subgroup'\midrule
	local prefoot \midrule
	local postfoot \bottomrule ///
$ENTER\end{longtable} ///
$ENTER\end{ThreePartTable}

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

capture program drop GetPrehead
program define GetPrehead, rclass
	syntax, [colformat(string) label(string) title(string) ]

	GetFootnotes, notes(`notes')
	local footnotes `"`r(footnotes)'"'

	if ("`colformat'"=="") local colformat C{2cm}
	if (`"`footnotes'"'!="") local insert_notes "\insertTableNotes"

	local prehead \centering /// Prevent centering captions that fit in single lines; don't put it in the preamble b/c that makes normal tables look ugly
$ENTER\captionsetup{singlelinecheck=false,labelfont=bf,labelsep=newline,font=bf,justification=justified} /// Different line for table number and table title
$ENTER\begin{ThreePartTable} ///
$ENTER$TAB\begin{TableNotes}$ENTER$TAB$TAB`footnotes'$ENTER$TAB\end{TableNotes} ///
$ENTER$TAB\begin{longtable}{l*{@M}{`colformat'}} /// {}  {c} {p{1cm}}
$ENTER$TAB\caption{`title'}\label{table:`label'} \\ ///
$ENTER$TAB\toprule\endfirsthead ///
$ENTER$TAB\midrule\endhead ///
$ENTER$TAB\midrule\endfoot ///
$ENTER$TAB`insert_notes'\endlastfoot
	return local prehead `"`prehead'"'
end

capture program drop GetFootnotes
program define GetFootnotes, rclass
syntax, [notes(string)]
	* TODO: Set this, note and vcvnote
	local starnote `"Levels of significance: ** p\(<0.05\), ** p\(<0.01\)."' // *** p<0.01, ** p<0.05, * p<0.1.

	local note "\Note{`vcvnote' `starnote' `note'}"
	local symbolnotes ${estdb_footnotes}${ENTER}
	local footnotes "`symbolnotes'`note'"
	return local footnotes `"`footnotes'"'
end

* Receive a keyword, looks it up, and i) returns the symbol, ii) updates the global with the footnotes
capture program drop AddFootnote
program define AddFootnote, rclass
	local footnote `0'
	if ("`footnote'"=="") {
		return local symbol ""
		exit
	}
	GetMetadata definition=`footnote'
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
		global estdb_footnotes "${estdb_footnotes}\item[`symbol'] `definition'`ENTER'`TAB'`TAB'"
	}
	local symbolcell "\tnote{`symbol'}"
	return local symbolcell "`symbolcell'"
end

capture program drop GetRHSVarlabels
program define GetRHSVarlabels, rclass
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

	return local rhslabels `"`varlabels'"'
	return local rhsorder `"`order'"'
end

capture program drop CompilePDF
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

capture program drop RunCMD
program define RunCMD
	if "$ESTDB_DEBUG"!="" {
		di as text "[cmd] " as input `"`0'"'
	}
	`0'
end

* Define globals and metadata (mata object)
capture program drop Initialize
program define Initialize
	syntax, verbose(integer)
	global TAB "`=char(9)'"
	global ENTER "`=char(13)'"
	global BACKSLASH "`=char(92)'"
	global indepvars // Ensure it's empty
	global estdb_footnotes // Ensure it's empty
	* Load metadata
	if (`verbose'>1) di as text "(loading metadata)"
	mata: read_metadata()
	* Clear potentialy possible previous estimates (from e.g. a failed run)
	cap estimates drop estdb*
	* Symbol mess
	mata: symboltoken = tokeninit()
	mata: symbols = "\textdagger \textsection \textparagraph \textdaggerdbl 1 2 3 4 5 6 7 8 9"
	mata: tokenset(symboltoken, symbols)
	* USAGE: mata: st_local("symbol", tokenget(symboltoken))  ... then assert_msg "`symbol'"!=""
	mata: symboldict = asarray_create() // dict: footnote -> symbol (for already used footnotes)
end

* Clear globals, mata objects, and saved estimates
capture program drop Cleanup
program define Cleanup
	* TODO: Ensure this function always get called when -Export- fails (like -reghdfe- does)
	global TAB
	global ENTER
	global BACKSLASH
	global indepvars
	global ESTDB_DEBUG
	global estdb_footnotes
	estimates drop estdb*
	mata: mata drop metadata symboltoken symbols symboldict
end

capture program drop GetMetadata
program define GetMetadata
* Syntax: GetMetadata MyLocal=key -> Will store metadata[key] in the local MyLocal
	local lclkey `0'
	if ("`lclkey'"=="") error 100
	gettoken lcl lclkey: lclkey , parse("=")
	gettoken equalsign key: lclkey , parse("=")
	local key footnotes.`key' // Remove blanks
	assert_msg "`key'"!="", msg("Key is empty! args=<`0'>")
	mata: st_local("key_exists", strofreal(asarray_contains(metadata, "`key'")))
	assert inlist(`key_exists', 0, 1)
	assert_msg `key_exists'==1, msg("metadata[`key'] does not exist")
	mata: st_local("value", asarray(metadata, "`key'"))
	c_local `lcl' = "`value'"
end
