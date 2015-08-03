capture program drop BuildPrehead
program define BuildPrehead
syntax, EXTension(string) [*]
	if ("`extension'"=="html") {
		BuildPreheadHTML, `options'
	}
	else {
		BuildPreheadTEX, `options'
	}
end

capture program drop BuildPreheadHTML
program define BuildPreheadHTML
syntax, colformat(string) size(integer) [title(string) label(string) ifcond(string asis)] ///
	orientation(string) [varwidth(string) colsep(string)] // THESE WILL BE IGNORED
	local hr = 32 * " "

	global quipu_prehead ///
		`"<!-- `hr' QUIPU - Stata Regression `hr'"' ///
		`"  - Criteria: `ifcond'"' ///
		`"  - Estimates: ${quipu_path}"' ///
		"-->" ///
		`"  <table class="estimates" name="`label'">"' ///
		`"  <caption>`title'</caption>"'
end

capture program drop BuildPreheadTEX
program define BuildPreheadTEX
syntax, orientation(string) [varwidth(string)] [*]
	
	if ("`varwidth'"!="") {
		* The [t] aligns the top of the varwidth block with the rest of the row
		local varlist_layout  "@{\begin{varwidth}[t]{`varwidth'}\narrowragged} l @{\end{varwidth}}"
	}
	else {
		local varlist_layout "l"
	}

	BuildPreheadTEX_`orientation', varlist_layout(`varlist_layout') `options'
	*global quipu_prehead : subinstr global quipu_prehead "#" "\#", all
end

capture program drop BuildPreheadTEX_landscape
program define BuildPreheadTEX_landscape
syntax, colformat(string) size(integer) varlist_layout(string) ///
	[title(string) label(string) ifcond(string asis)] ///
	[colsep(string)]

	local hr = 32 * "*"
    local size_names tiny scriptsize footnotesize small normalsize large Large LARGE huge Huge
    local size_colseps 04 11 11 30 30 30 30 30 30 30 // 04 = 0.04cm

	local bottom = cond(`size'<=2, 2, 3)
    local size_name : word `size' of `size_names'
    local size_colseps : word `size' of `size_colseps' // set default

    if ("`colsep'"=="") local colsep 0.`size_colseps'cm

	global quipu_prehead ///
		`"\newgeometry{bottom=`bottom'cm}$ENTER\begin{landscape}$ENTER\setlength\LTcapwidth{\linewidth}"' ///
		`"$BACKSLASH`size_name'"' ///
		`"\tabcolsep=`colsep'"' ///
		`"\centering"' ///
		`"\captionsetup{singlelinecheck=off,labelfont=bf,labelsep=newline,font=bf,justification=justified}"' /// Different line for table number and table title
		`"\begin{ThreePartTable}"' ///
		`"\renewcommand{\TPTminimum}{\linewidth}"' ///
		`"$TAB\begin{TableNotes}$ENTER$TAB$TAB\${quipu_footnotes}$ENTER$TAB\end{TableNotes}"' ///
		`"$TAB\begin{longtable}{`varlist_layout' *{@M}{`colformat'}}"' /// {}  {c} {p{1cm}}
		`"$TAB\caption{`title'}\label{table:`label'} \\"' ///
		`"$TAB\toprule\endfirsthead"' ///
		`"$TAB\midrule\endhead"' ///
		`"$TAB\midrule\endfoot"' ///
		`"$TAB\${quipu_insertnote}\endlastfoot"'
end

capture program drop BuildPreheadTEX_portrait
program define BuildPreheadTEX_portrait
syntax, colformat(string) size(integer) varlist_layout(string) ///
	[title(string) label(string) ifcond(string asis)] ///
	colsep(string)

	local hr = 32 * "*"
    local size_names tiny scriptsize footnotesize small normalsize large Large LARGE huge Huge
    local size_colseps 04 11 11 30 30 30 30 30 30 30 // 04 = 0.04cm

	local bottom = cond(`size'<=2, 2, 3)
    local size_name : word `size' of `size_names'
    local size_colseps : word `size' of `size_colseps'

    if ("`colsep'"=="") local colsep 0.`size_colseps'cm

	global quipu_prehead ///
		`"{"' ///
		`"$BACKSLASH`size_name'"' ///
		`"\tabcolsep=`colsep'"' ///
		`"\centering"' /// Prevent centering captions that fit in single lines; don't put it in the preamble b/c that makes normal tables look ugly
		`"\captionsetup{singlelinecheck=on,labelfont=bf,labelsep=colon,font=bf,justification=centering}"' ///
		`"\begin{ThreePartTable}"' ///
		`"\renewcommand{\TPTminimum}{0.9\textwidth}"' /// textwidth vs linewidth
		`"$TAB\begin{TableNotes}$ENTER$TAB$TAB\${quipu_footnotes}$ENTER$TAB\end{TableNotes}"' ///
		`"$TAB\begin{longtable}{`varlist_layout' *{@M}{`colformat'}}"' /// {}  {c} {p{1cm}}
		`"$TAB\caption{`title'}\label{table:`label'} \\"' ///
		`"$TAB\toprule\endfirsthead"' ///
		`"$TAB\midrule\endhead"' ///
		`"$TAB\midrule\endfoot"' ///
		`"$TAB\${quipu_insertnote}\endlastfoot"'
end

capture program drop BuildPreheadTEX_inline
program define BuildPreheadTEX_inline
syntax, colformat(string) size(integer) [title(string) label(string) ifcond(string asis)] ///
	colsep(string)

	local hr = 32 * "*"
    local size_names tiny scriptsize footnotesize small normalsize large Large LARGE huge Huge
    local size_colseps 04 11 11 30 30 30 30 30 30 30 // 04 = 0.04cm

	local bottom = cond(`size'<=2, 2, 3)
    local size_name : word `size' of `size_names'
    local size_colseps : word `size' of `size_colseps'

    if ("`colsep'"=="") local colsep 0.`size_colseps'cm

	global quipu_prehead ///
		`"$ENTER\begin{comment}"' ///
		`"$TAB`hr' QUIPU - Stata Regression `hr'"' ///
		`"$TAB - Criteria: `ifcond'"' ///
		`"$TAB - Estimates: ${quipu_path}"' ///
		`"\end{comment}"' ///
		`"{"' ///
		`"$BACKSLASH`size_name'"' ///
		`"\begin{table}[!thbp]"' ///
		`"\tabcolsep=`colsep'"' ///
		`"\centering"' /// Prevent centering captions that fit in single lines; don't put it in the preamble b/c that makes normal tables look ugly
		`"\captionsetup{singlelinecheck=on,labelfont=bf,labelsep=colon,font=bf,justification=centering}"' ///
		`"\begin{ThreePartTable}"' ///
		`"\renewcommand{\TPTminimum}{0.9\textwidth}"' /// textwidth vs linewidth
		`"$TAB\caption{`title'}\label{table:`label'}"' ///
		`"$TAB\begin{tabular}{`varlist_layout' *{@M}{`colformat'}}"' /// {}  {c} {p{1cm}}
		`"$TAB\toprule"'
end
