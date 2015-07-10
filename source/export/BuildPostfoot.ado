capture program drop BuildPostfoot
program define BuildPostfoot
syntax, EXTension(string) [*]
	if ("`extension'"=="html") {
		BuildPostfootHTML, `options'
	}
	else {
		BuildPostfootTEX, `options'
	}
end

capture program drop BuildPostfootHTML
program define BuildPostfootHTML
syntax, [*]
	global quipu_postfoot `"  </tfoot>$ENTER$ENTER  </table>${quipu_footnotes}"'
end

capture program drop BuildPostfootTEX
program define BuildPostfootTEX
syntax, orientation(string) [*] [PAGEBREAK]
	* clearpage vs newpage http://tex.stackexchange.com/questions/45609/is-it-wrong-to-use-clearpage-instead-of-newpage
	local flush = cond("`pagebreak'"!="", "$ENTER\newpage", "")
	BuildPostfootTEX_`orientation', `options' flush(`flush')
end

capture program drop BuildPostfootTEX_landscape
program define BuildPostfootTEX_landscape
syntax, [flush(string)] size(integer) 
	global quipu_postfoot ///
		`"$TAB\bottomrule"' ///
		`"$TAB\end{longtable}"' ///
		`"\end{ThreePartTable}"' ///
		`"\vspace{-5pt}$ENTER\end{landscape}"' ///
		`"\restoregeometry`flush'"'
end

capture program drop BuildPostfootTEX_portrait
program define BuildPostfootTEX_portrait
syntax, [flush(string)] size(integer)
	global quipu_postfoot ///
		`"$TAB\bottomrule"' ///
		`"$TAB\end{longtable}"' ///
		`"\end{ThreePartTable}"' ///
		`"\vspace{15pt}$ENTER}"' ///
		`"\restoregeometry`flush'"'
end

capture program drop BuildPostfootTEX_inline
program define BuildPostfootTEX_inline
syntax, [flush(string)] size(integer)
	global quipu_postfoot ///
		`"$TAB\bottomrule"' ///
		`"$TAB\end{tabular}"' ///
		`"$TAB\begin{TableNotes}$ENTER$TAB$TAB\${quipu_footnotes}$ENTER$TAB\end{TableNotes}"' ///
		`"\end{ThreePartTable}"' ///
		`"\end{table}"' /// `"\vspace{15pt}"' ///
		`"$ENTER}"'
end
