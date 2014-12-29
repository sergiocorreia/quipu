cap pr drop Replay
program define Replay
syntax [anything(everything)] , [*]
	qui Use `anything'
	forv i=1/`c(N)' {
		local fn = path[`i'] +"/"+filename[`i']
		di as text _n "{bf:replay `i'/`c(N)':}"
		estdb view "`fn'"
		di as text "{hline}"
	}
	clear
end
