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
	header = ""
	read_level(1, header, metadata, fh)
	fclose(fh)
}

string read_level(real level, string header, pointer container, real fh)
{
	dict = asarray_create() // current dict that will be saved in container
	(" "*level*4 + "[" + header + "]")

	while ( ( line = strtrim(fget(fh)) ) != J(0,0,"") ) {

		//  Ignore comments
		if ( strpos(line, "*")==1 | strlen(line)==0 ) continue

		// Add keys to container
		if ( strpos(line, "#")!=1 ) {
			printf(" "*level*4 + "... %s\n", line)
		}
		// Change container (new nested, new same level, or back to prev)
		else {
			// Get new level
			regexm(line, "^(#+)(.+)")
			oldheader = header
			oldlevel = level
			level = strlen(regexs(1))
			header = strtrim(regexs(2))
			assert( abs(level-oldlevel) <= 1 )

			if (level<oldlevel) {
				break
			}
			else if (level==oldlevel & strlen(header)>0) {
				(" "*oldlevel*4 + "saving " + oldheader + " (same level)")
				asarray(container, oldheader, dict) // save existing dict
				(" "*level*4 + "[" + header + "]")
				dict = asarray_create() // create empty dict
				oldheader = "" // redundant?
			}
			else if (level>oldlevel) {
				(" "*oldlevel*4 + "diving from" + oldheader + " to " + header)
				header = read_level(level, header, dict, fh)
				problema puedo regresar de lvl 4 a lvl 1
				(" "*oldlevel*4 + "saving " + oldheader + " (backed up)")
				asarray(container, oldheader, dict) // container[header] = dict

				(">>> backed up to " + header)
				
				("[SAVING]" + header + " (tail)")
				dict = asarray_create()
			}
			header = newheader
		} // end of header handling
	} // end of line looping

	//  save dict in container
	assert(strlen(oldheader)>0)
	(" "*oldlevel*4 + "saving " + oldheader + " (tail)")
	asarray(container, oldheader, dict) // container[header] = dict
	return(header)
}

end


mata: read_metadata()
mata:
	mata desc
	asarray_contains(metadata, "footnotes")
	asarray(metadata, "footnotes")
	asarray_contains(metadata, "groups")
	asarray_contains(metadata, "subgroups")
end
exit
