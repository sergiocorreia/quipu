capture program drop BuildFootnotes
program define BuildFootnotes
syntax, EXTension(string) stars(string) [notes(string)] [vcnote(string)]
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

	local sep1 = cond("${quipu_vcenote}"!="" & "`starnote'`notes'"!="", " ", "")
	local sep2 = cond("${quipu_vcenote}`starnote'"!="" & "`notes'"!="", " ", "")
	
	if ("`extension'"=="html") {
		local note "<em>Note.&mdash; </em>${quipu_vcenote}`sep1'`starnote'`sep2'`notes'"
		local summary "<summary>Regression notes</summary>"
		if (`"${quipu_footnotes}"'!="") {
			global quipu_footnotes `"<details open>${ENTER}`summary'${ENTER}  <dl class="estimates-notes">${ENTER}${quipu_footnotes}</dl>${ENTER}  <p class="estimates-notes">`note'</p></details>"'
		}
		else {
			global quipu_footnotes `"<details open>`note'</details>"'
		}
	}
	else {
		local note `"\Note{${quipu_vcenote}`sep1'`starnote'`sep2'`notes'}"'
		if (`"${quipu_footnotes}"'!="") {
			global quipu_footnotes `"${ENTER}`summary'${ENTER}${TAB}${ENTER}${quipu_footnotes}${ENTER}${TAB}`note'"'
		}
		else {
			global quipu_footnotes `"`note'"'
		}
	}



	* ThreePartTable fails w/out footnotes (although above we are kinda ensuring it will not be empty)
	if (`"$quipu_footnotes"'!="") global quipu_insertnote "\insertTableNotes"
	global quipu_starlevels starlevels(`starlevels')
end
