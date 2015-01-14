* Clear globals, mata objects, and saved estimates
capture program drop Cleanup
program define Cleanup
	* TODO: Ensure this function always get called when -Export- fails (like -reghdfe- does)
	global TAB
	global ENTER
	global BACKSLASH
	global indepvars
	global estdb_verbose

	global estdb_prehead
	global estdb_header
	global estdb_footnotes
	global estdb_insertnote
	global estdb_rhsoptions
	global estdb_prefoot
	global estdb_postfoot
	global estdb_starlevels

	clear
	cap estimates drop estdb*
	local mata_objects metadata symboltoken symbols symboldict
	foreach obj of local mata_objects {
		cap mata: mata drop `obj'
	}
end
