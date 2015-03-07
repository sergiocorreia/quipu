cap pr drop Replay
program define Replay
syntax [anything(everything)] , [*] [CLS]
	qui Use `anything'
	
	local more = c(more)
	if ("`cls'"!="") set more on
	cap `cls'

	forv i=1/`c(N)' {
		local fn = path[`i'] +"/"+filename[`i']
		local num_estimate = num_estimate[`i']
		if ("`cls'"=="") di
		di as text "{bf:replay `i'/`c(N)':}"
		quipu view `fn' , n(`num_estimate')
		if ("`cls'"=="") di as text "{hline}"
		if ("`cls'"!="") more
		cap `cls'
	}
	clear
	set more `more'
end
