capture program drop RunCMD
program define RunCMD
	if ($estdb_verbose>0) {
		di as text "[cmd] " as input `"`0'"'
	}
	`0'
end
