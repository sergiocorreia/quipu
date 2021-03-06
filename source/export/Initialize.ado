capture program drop Initialize
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
