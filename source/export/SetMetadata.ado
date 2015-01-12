capture program drop SetMetadata
program define SetMetadata
	* [Syntax] SetMetadata key1.key2=value
	assert "`0'"!=""
	gettoken key 0: 0 , parse("=")
	gettoken equalsign value: 0 , parse("=")
	local key `key' // trim spaces
	local value `value' // trim spaces
	di as error `"metadata[`key'] = <`value'>"'
	mata: asarray(metadata, "`key'", `"`value'"')
end
