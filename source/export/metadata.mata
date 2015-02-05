// -------------------------------------------------------------------------------------------------
// Import metadata.txt (kinda-markdown-syntax with metadata for footnotes, etc.)
// -------------------------------------------------------------------------------------------------
mata:
mata set matastrict off

void read_metadata()
{
	external metadata
	fn = st_global("quipu_path") + "/" + "metadata.txt"
	fh = fopen(fn, "r")
	metadata = asarray_create() // container dict
	headers = J(1, 5, "")
	level = 0
	i = 0
	is_verbose = st_local("verbose")!="0"

	while ( ( line = strtrim(fget(fh)) ) != J(0,0,"") ) {
		//  Ignore comments
		if ( strpos(line, "*")==1 | strlen(line)==0 ) continue

		// Remove leading dash
		if (substr(line, 1, 1)=="-") {
			line = strtrim(substr(line, 2, .))
		}

		// Check that the line contents are not empty
		assert(strlen(subinstr(line, "#", "", .)))
		// metadata[header1.header2...key] = value
		if ( strpos(line, "#")!=1 ) {
			_ = regexm(line, "^[ \t]?([a-zA-Z0-9_]+)[ \t]?:(.+)$")
			if (_==0) {
				printf("{txt}key:value line could not be parsed <" + line + ">")
			}
			assert (_==1)
			assert(strlen(strtrim(regexs(1)))>0)
			assert(strlen(strtrim(regexs(2)))>0)
			headers[level+1] = regexs(1)
			value = strtrim(regexs(2))
			key = invtokens(headers[., (1..level+1)], ".")
			assert(asarray_contains(metadata, key)==0) // assert key not in metadata
			++i
			asarray(metadata, key, value) // metadata[key] = value
			// printf("metadata.%s=<%s>\n", key, value)
		}
		// Get header and level
		else {
			_ = regexm(line, "^(#+)(.+)")
			level = strlen(regexs(1))
			headers[level] = strtrim(regexs(2))
		}
	}
	fclose(fh)
	if (is_verbose) {
		printf("{txt}(%s key-value pairs added to quipu metadata)\n", strofreal(i))
	}
}
end
