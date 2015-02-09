capture program drop BuildPosthead
program define BuildPosthead
syntax, EXTension(string) [*]
	if ("`extension'"=="html") {
		BuildPostheadHTML, `options'
	}
	else {
		BuildPostheadTEX, `options'
	}
end

capture program drop BuildPostheadHTML
program define BuildPostheadHTML
syntax, [*]
	global quipu_posthead `"  <tbody>$ENTER"'
end

capture program drop BuildPostheadTEX
program define BuildPostheadTEX
syntax, [*]
	global quipu_posthead "  <tbody>$ENTER"
end
