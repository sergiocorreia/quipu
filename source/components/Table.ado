cap pr drop Table
program define Table
syntax [anything(everything)] , [*]
	cap estimates drop estdb*
	qui Use `anything'
	forv i=1/`c(N)' {
		local fn = path[`i'] +"/"+filename[`i']
		estimates use "`fn'"
		estimates title: "`fn'"
		estimates store estdb`i', nocopy
	}
	clear
	estimates table _all , `options'
	estimates drop estdb*
end

