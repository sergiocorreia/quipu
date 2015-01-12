capture program drop Prehead
program define Prehead, rclass
	syntax, [colformat(string) label(string) title(string) ]

	GetFootnotes, notes(`notes')
	local footnotes `"`r(footnotes)'"'

	if ("`colformat'"=="") local colformat C{2cm}
	if (`"`footnotes'"'!="") local insert_notes "\insertTableNotes"

	local prehead \centering /// Prevent centering captions that fit in single lines; don't put it in the preamble b/c that makes normal tables look ugly
$ENTER\captionsetup{singlelinecheck=false,labelfont=bf,labelsep=newline,font=bf,justification=justified} /// Different line for table number and table title
$ENTER\begin{ThreePartTable} ///
$ENTER$TAB\begin{TableNotes}$ENTER$TAB$TAB`footnotes'$ENTER$TAB\end{TableNotes} ///
$ENTER$TAB\begin{longtable}{l*{@M}{`colformat'}} /// {}  {c} {p{1cm}}
$ENTER$TAB\caption{`title'}\label{table:`label'} \\ ///
$ENTER$TAB\toprule\endfirsthead ///
$ENTER$TAB\midrule\endhead ///
$ENTER$TAB\midrule\endfoot ///
$ENTER$TAB`insert_notes'\endlastfoot
	return local prehead `"`prehead'"'
end
