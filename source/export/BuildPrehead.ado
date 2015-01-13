capture program drop BuildPrehead
program define BuildPrehead
	syntax, colformat(string) [title(string) label(string) ifcond(string asis)]
	local hr = 32 * "*"
	global estdb_prehead $ENTER\begin{comment} ///
		"$TAB`hr' ESTDB - Stata Regression `hr'" ///
		`"$TAB - Criteria: `ifcond'"' ///
		`"$TAB - Estimates: ${estdb_path}"' ///
		"\end{comment}" ///
		"\centering" /// Prevent centering captions that fit in single lines; don't put it in the preamble b/c that makes normal tables look ugly
		"\captionsetup{singlelinecheck=false,labelfont=bf,labelsep=newline,font=bf,justification=justified}" /// Different line for table number and table title
		"\begin{ThreePartTable}" ///
		"$TAB\begin{TableNotes}$ENTER$TAB$TAB\${estdb_footnotes}$ENTER$TAB\end{TableNotes}" ///
		"$TAB\begin{longtable}{l*{@M}{`colformat'}}" /// {}  {c} {p{1cm}}
		"$TAB\caption{`title'}\label{table:`label'} \\" ///
		"$TAB\toprule\endfirsthead" ///
		"$TAB\midrule\endhead" ///
		"$TAB\midrule\endfoot" ///
		"$TAB\${estdb_insertnote}\endlastfoot"
end
