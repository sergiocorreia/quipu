* Receive a keyword, looks it up, and i) returns the symbol, ii) updates the global with the footnotes
capture program drop AddFootnote
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
