capture program drop Browse
program define Browse
syntax [anything(everything)]
	qui Use `anything'
	browse
end

