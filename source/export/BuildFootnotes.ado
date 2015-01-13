capture program drop BuildFootnotes
program define BuildFootnotes
syntax, [notes(string)] [vcnote(string)]
	* BUGBUG: Autoset starnote and vcnote!!!
	local starnote `"Levels of significance: ** p\(<0.05\), ** p\(<0.01\)."' // *** p<0.01, ** p<0.05, * p<0.1.
	local note "\Note{`vcvnote' `starnote' `note'}"
	if (`"${estdb_footnotes}"'!="") {
		global estdb_footnotes `"${estdb_footnotes}${ENTER}$TAB$TAB`note'"'
	}
	else {
		global estdb_footnotes `"`note'"'
	}

	* ThreePartTable fails w/out footnotes (although above we are kinda ensuring it will not be empty)
	if (`"$estdb_footnotes"'!="") global estdb_insertnote "\insertTableNotes"
end
