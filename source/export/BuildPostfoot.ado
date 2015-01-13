capture program drop BuildPostfoot
program define BuildPostfoot
	global estdb_postfoot $TAB\bottomrule ///
		"$TAB\end{longtable}" ///
		"\end{ThreePartTable}"
end
