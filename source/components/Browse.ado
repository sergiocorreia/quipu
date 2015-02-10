capture program drop Browse
program define Browse
syntax [anything(everything)] , [MOVED(string asis)]
	qui Use `anything', moved(`"`moved'"')
	browse
end

