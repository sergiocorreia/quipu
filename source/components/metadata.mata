// -------------------------------------------------------------------------------------------------
// Import metadata.txt (kinda-markdown-syntax with metadata for footnotes, etc.)
// -------------------------------------------------------------------------------------------------
mata:
mata set matastrict off

void read_metadata()
{
	external metadata
	fn = st_global("estdb_path") + "/" + "metadata.txt"
	fh = fopen(fn, "r")
	metadata = asarray_create() // container dict
	headers = J(1, 4, "")
	level = 0

	while ( ( line = strtrim(fget(fh)) ) != J(0,0,"") ) {
		//  Ignore comments
		if ( strpos(line, "*")==1 | strlen(line)==0 ) continue

		// Add keys to container
		if ( strpos(line, "#")!=1 ) {
			header = "SUBKEY"
			key = invtokens(headers[., (1..level+1)], ".")
			printf(" "*level*4 + key + header + "= %s\n", line)
		// Get header and level
		else {
			regexm(line, "^(#+)(.+)")
			level = strlen(regexs(1))
			headers[level] = strtrim(regexs(2))
		}
		headers[(1..level)] // print
	}
	fclose(fh)
}

end


mata: read_metadata()
mata:
	mata desc
	asarray_contains(metadata, "footnotes.growth")
	asarray(metadata, "footnotes.growth")
end
exit
