capture program drop Footnotes
program define Footnotes, rclass
syntax, [notes(string)]
	* TODO: Set this, note and vcvnote
	local starnote `"Levels of significance: ** p\(<0.05\), ** p\(<0.01\)."' // *** p<0.01, ** p<0.05, * p<0.1.

	local note "\Note{`vcvnote' `starnote' `note'}"
	local symbolnotes ${estdb_footnotes}${ENTER}
	local footnotes "`symbolnotes'`note'"
	return local footnotes `"`footnotes'"'
end
