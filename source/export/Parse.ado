capture program drop Parse
program define Parse
	syntax [anything(everything)] , ///
		as(string) /// tex pdf html
		[VERBOSE(integer 0) /// 0=No Logging, 2=Log Everything
		VIEW /// Open the PDF viewer at the end?
		LATEX_engine(string) /// xelatex (smaller pdfs, better fonts) or pdflatex (faster)
		SIZE(integer 5) ORIENTation(string) PAGEBREAK /// More PDF options
		COLFORMAT(string) /// Alternatives include 1) D{.}{.}{-1} with dcolumn 2) c 3) p{2cm} 4) C{2cm} with array + a custom cmd
		NOTEs(string) /// Misc notes (i.e. everything besides the glossaries for symbols, stars, and vcv)
		VCVnote(string) /// Note regarding std. errors, in case default msg is not good enough
		TITLE(string) ///
		LABEL(string) /// Used in TeX labels
		RENAME(string asis) /// This is for REGEX replaces, which encompass normal ones. Note we are matching entire strings (adding ^$)
		DROP(string asis) /// REGEX drops, which encompass normal ones.
		HEADER(string) /// Each word will indicate a row in the header. Valid ones are either in e() or #.
		METAdata(string asis) /// Additional metadata to override the one from the markdown file
		Order(string asis) VARLabels(string asis) /// ESTOUT TRAP OPTIONS: Will be silently ignored!
		] [*]
	* Note: Remember to update any changes here before the bottom c_local!

	assert_msg inlist("`verbose'", "0", "1", "2"), msg("Wrong verbose level (needs to be 0, 1 or 2)")
	global estdb_verbose `verbose'

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
	
	* Inject values into caller (Export.ado)
	local names filename ifcond tex pdf html view latex_engine orientation size pagebreak ///
		colformat notes vcvnote title label ///
		rename drop header metadata options
	if ($estdb_verbose>1) di as text "Parsed options:"
	foreach name of local names {
		if (`"``name''"'!="") {
			if ($estdb_verbose>1) di as text `"  `name' = "' as result `"``name''"'
			c_local `name' `"``name''"'
		}
	}
end

capture program drop ParseUsingIf
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
