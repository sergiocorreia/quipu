capture program drop BuildPrefoot
program define BuildPrefoot
	syntax, EXTension(string)
	if ("`extension'"=="html") {
		global quipu_prefoot "  </tbody>$ENTER$ENTER  <tfoot>$ENTER"
	}
	else {
		global quipu_prefoot "$TAB\midrule"
	}
end
