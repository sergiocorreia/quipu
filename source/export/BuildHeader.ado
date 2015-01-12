capture program drop BuildHeader
program define BuildHeader
* Save results in $estdb_header
	syntax, header(string)
	foreach cat of local header {
		...
	}
end
