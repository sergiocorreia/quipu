capture program drop Prehead
program define Prehead, rclass
	syntax, [colformat(string) label(string) title(string) ]

	Footnotes, notes(`notes')
	local footnotes `"`r(footnotes)'"'

	if ("`colformat'"=="") local colformat C{2cm}
	if (`"`footnotes'"'!="") local insert_notes "\insertTableNotes"

	local prehead \centering /// Prevent centering captions that fit in single lines; don't put it in the preamble b/c that makes normal tables look ugly
"\captionsetup{singlelinecheck=false,labelfont=bf,labelsep=newline,font=bf,justification=justified}" /// Different line for table number and table title
"\begin{ThreePartTable}" ///
"$TAB\begin{TableNotes}$ENTER$TAB$TAB`footnotes'$ENTER$TAB\end{TableNotes}" ///
"$TAB\begin{longtable}{l*{@M}{`colformat'}}" /// {}  {c} {p{1cm}}
"$TAB\caption{`title'}\label{table:`label'} \\" ///
"$TAB\toprule\endfirsthead" ///
"$TAB\midrule\endhead" ///
"$TAB\midrule\endfoot" ///
"$TAB`insert_notes'\endlastfoot"
	return local prehead `"`prehead'"'
end
