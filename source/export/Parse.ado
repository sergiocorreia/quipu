capture program drop Parse
program define Parse
	syntax [anything(everything)] , ///
		[VERBOSE(integer 0) /// 0=No Logging, 2=Log Everything
		VIEW /// Open the PDF/HTML viewer  at the end?
		ENGINE(string) /// xelatex (smaller pdfs, better fonts) or pdflatex (faster)
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
	* Will save 3 locals: filename (full path+fn WITHOUT THE EXT!), extension, and ifcond
	ParseUsingIf `anything'

	* Set default options
	if ("`header'"=="") local header depvar #
	if ("`colformat'"=="") local colformat C{2cm}
	if ("`engine'"=="") local engine "xelatex"
	assert_msg inlist("`engine'", "xelatex", "pdflatex"), msg("invalid latex engine: `engine'")
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
	local names filename ext ifcond tex pdf html view engine orientation size pagebreak ///
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

capture program drop ParseUsingIf
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
