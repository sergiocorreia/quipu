capture program drop Initialize
program define Initialize
	global TAB "`=char(9)'"
	global ENTER "`=char(13)'"
	global BACKSLASH "`=char(92)'"
	global indepvars // Ensure it's empty
	global estdb_footnotes // Ensure it's empty
	
	* Load metadata
	if ($estdb_verbose>1) di as text "(loading metadata)"
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
