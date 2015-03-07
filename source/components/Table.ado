cap pr drop Table
program define Table
syntax [anything(everything)] , [*]
	cap estimates drop quipu*
	qui Use `anything'
	forv i=1/`c(N)' {
		local fn = path[`i'] +"/"+filename[`i']
		local num_estimate = num_estimate[`i']
		estimates use "`fn'", number(`num_estimate')
		estimates title: "`fn'"
		estimates store quipu`i', nocopy
	}
	clear
	estimates table _all , `options'
	estimates drop quipu*
end

