cap pr drop Table
program define Table
syntax, index(string) [cond(string asis) sort(string) sortmerge(string)] [*]
	Use, index(`index') cond(`cond') sort(`sort') sortmerge(`sortmerge')
	estimates table _all , `options'
end

