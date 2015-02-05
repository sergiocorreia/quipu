* Clear globals, mata objects, and saved estimates
capture program drop Cleanup
program define Cleanup
	* TODO: Ensure this function always get called when -Export- fails (like -reghdfe- does)
	global TAB
	global ENTER
	global BACKSLASH
	global indepvars
	global quipu_verbose

	global quipu_prehead
	global quipu_header
	global quipu_footnotes
	global quipu_insertnote
	global quipu_rhsoptions
	global quipu_prefoot
	global quipu_postfoot
	global quipu_starlevels
	global quipu_vcenote
	global quipu_stats

	clear
	cap estimates drop quipu*
	local mata_objects metadata symboltoken symbols symboldict
	foreach obj of local mata_objects {
		cap mata: mata drop `obj'
	}
end
