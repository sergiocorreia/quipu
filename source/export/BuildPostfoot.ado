capture program drop BuildPostfoot
program define BuildPostfoot
syntax, orientation(string) size(integer) [PAGEBREAK]

	if ("`orientation'"=="landscape") {
		local wrapper "\vspace{-5pt}$ENTER\end{landscape}"
	}
	else {
		local wrapper "\vspace{15pt}$ENTER}"
	}

	* clearpage vs newpage http://tex.stackexchange.com/questions/45609/is-it-wrong-to-use-clearpage-instead-of-newpage
	local flush = cond("`pagebreak'"!="", "$ENTER\newpage", "")

	global estdb_postfoot $TAB\bottomrule ///
		"$TAB\end{longtable}" ///
		"\end{ThreePartTable}" ///
		"`wrapper'" ///
		"\restoregeometry`flush'"
end
