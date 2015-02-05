capture program drop CompilePDF
program define CompilePDF
	syntax, filename(string) latex_engine(string)
	
	* Get folder
	local tmp `filename'
	local left
	local dir
	while strpos("`tmp'", "/")>0 | strpos("`tmp'", "\")>0 {
		local dir `macval(dir)'`macval(left)' // if we run this at the end of the while, we will keep the /
		* We need -macval- to deal with the "\" in `dir' interfering with the `' in left
		gettoken left tmp : tmp, parse("/\")
	}

	tempfile stderr stdout
	cap erase "`filename'.pdf" // I don't want to BELIEVE there is no bug
	if ($quipu_verbose<=1) local quiet "-quiet"
	RunCMD shell `latex_engine' "`filename'.tex" -halt-on-error `quiet' -output-directory="`dir'" 2> "`stderr'" 1> "`stdout'" // -quiet
	if ($quipu_verbose>1) noi type "`stderr'"
	if ($quipu_verbose>1) di as text "{hline}"
	if ($quipu_verbose>1) noi type "`stdout'"
	cap conf file "`filename'.pdf"
	if _rc==601 {
		di as error "(pdf could not be created - run with -verbose(2)- to see details)"
		exit 601
	}
end
