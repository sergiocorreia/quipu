capture program drop BuildFootnotes
program define BuildFootnotes
syntax, stars(string) [notes(string)] [vcnote(string)]
	* BUGBUG: Autoset starnote and vcnote!!!

	local stars : list sort stars // Sort it
	local numstars : word count `stars'
	local starnote "Levels of significance: "
	forval i = `numstars'(-1)1 {
		local sign = "*" * `=`numstars'-`i'+1'
		local num : word `i' of `stars'
		local sep = cond(`i'>1, ", ", ".")
		local starnote "`starnote' `sign' \(p<`num'\)`sep'"
		local starlevels "`starlevels' `sign' `num'"
	}

	local sep1 = cond("${estdb_vcenote}"!="" & "`starnote'`note'"!="", " ", "")
	local sep2 = cond("${estdb_vcenote}`starnote'"!="" & "`note'"!="", " ", "")
	local note "\Note{${estdb_vcenote}`sep1'`starnote'`sep2'`note'}"

	if (`"${estdb_footnotes}"'!="") {
		global estdb_footnotes `"${estdb_footnotes}${ENTER}$TAB$TAB`note'"'
	}
	else {
		global estdb_footnotes `"`note'"'
	}

	* ThreePartTable fails w/out footnotes (although above we are kinda ensuring it will not be empty)
	if (`"$estdb_footnotes"'!="") global estdb_insertnote "\insertTableNotes"
	global estdb_starlevels starlevels(`starlevels')
end
