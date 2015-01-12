* Receive a keyword, looks it up, and i) returns the symbol, ii) updates the global with the footnotes
capture program drop AddFootnote
program define AddFootnote, rclass
	local footnote `0'
	if ("`footnote'"=="") {
		return local symbol ""
		exit
	}
	GetMetadata definition=footnote.`footnote'
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
