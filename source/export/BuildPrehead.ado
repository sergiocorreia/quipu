capture program drop BuildPrehead
program define BuildPrehead
syntax, colformat(string) orientation(string) size(integer) [title(string) label(string) ifcond(string asis)]

	local hr = 32 * "*"
    local size_names tiny scriptsize footnotesize small normalsize large Large LARGE huge Huge
    local size_colseps 04 11 11 30 30 30 30 30 30 30 // 04 = 0.04cm

	local bottom = cond(`size'<=2, 2, 3)
	if ("`orientation'"=="landscape") {
		local wrapper "\newgeometry{bottom=`bottom'cm}$ENTER\begin{landscape}$ENTER\setlength\LTcapwidth{\textwidth}"
	}
	else {
		local wrapper "{"
	}
    local size_name : word `size' of `size_names'
    local size_colseps : word `size' of `size_colseps'

	global quipu_prehead $ENTER\begin{comment} ///
		"$TAB`hr' QUIPU - Stata Regression `hr'" ///
		`"$TAB - Criteria: `ifcond'"' ///
		`"$TAB - Estimates: ${quipu_path}"' ///
		"\end{comment}" ///
		"`wrapper'" ///
		"$BACKSLASH`size_name'" ///
		"\tabcolsep=0.`size_colseps'cm" ///
		"\centering" /// Prevent centering captions that fit in single lines; don't put it in the preamble b/c that makes normal tables look ugly
		"\captionsetup{singlelinecheck=false,labelfont=bf,labelsep=newline,font=bf,justification=justified}" /// Different line for table number and table title
		"\begin{ThreePartTable}" ///
		"$TAB\begin{TableNotes}$ENTER$TAB$TAB\${quipu_footnotes}$ENTER$TAB\end{TableNotes}" ///
		"$TAB\begin{longtable}{l*{@M}{`colformat'}}" /// {}  {c} {p{1cm}}
		"$TAB\caption{`title'}\label{table:`label'} \\" ///
		"$TAB\toprule\endfirsthead" ///
		"$TAB\midrule\endhead" ///
		"$TAB\midrule\endfoot" ///
		"$TAB\${quipu_insertnote}\endlastfoot"
end
