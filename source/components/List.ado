cap pr drop List
program define List
syntax [anything(everything)] , [*]
	qui Use `anything'
	qui ds path filename time, not
	list `r(varlist)' , `options' constant
	return clear
end

/*
 [cond(string asis) sort(string) sort(string) sortmerge(string)] [*]
	Use, index(`index') cond(`cond') sort(`sort') sortmerge(`sortmerge')
	* estimates table est*
	forv i=1/`r(num_estimates)' {
		estimates replay _all
	}

end

*/
