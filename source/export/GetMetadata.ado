capture program drop GetMetadata
program define GetMetadata
* Syntax: GetMetadata MyLocal=key -> Will store metadata[key] in the local MyLocal
	local lclkey `0'
	if ("`lclkey'"=="") error 100
	gettoken lcl lclkey: lclkey , parse("=")
	gettoken equalsign key: lclkey , parse("=")
	local key `key' // Remove blanks
	assert_msg "`key'"!="", msg("Key is empty! args=<`0'>")
	mata: st_local("key_exists", strofreal(asarray_contains(metadata, "`key'")))
	assert inlist(`key_exists', 0, 1)
	assert_msg `key_exists'==1, msg("metadata[`key'] does not exist") rc(510)
	mata: st_local("value", asarray(metadata, "`key'"))
	c_local `lcl' `"`value'"'
end
