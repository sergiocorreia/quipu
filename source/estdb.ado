// -------------------------------------------------------------------------------------------------
// ESTDB - Save and manage regr. estimates and report tables via -estout-
// -------------------------------------------------------------------------------------------------
capture program drop estdb
program define estdb
	local subcmd_list associate setpath add build_index update_varlist
	* save index describe use browse list view table report

	* Remove subcmd from 0
	gettoken subcmd 0 : 0, parse(" ,:")

	* Expand abbreviations and call appropiate subcommand
	if (substr("`subcmd'", 1,2)=="de") local subcmd "describe"
	if (substr("`subcmd'", 1,2)=="br") local subcmd "browse"
	if (substr("`subcmd'", 1,2)=="li") local subcmd "list"
	if (substr("`subcmd'", 1,5)=="build") local subcmd "build_index"
	if (substr("`subcmd'", 1,6)=="update") local subcmd "update_varlist"
	local subcmd_commas : subinstr local subcmd_list " "   `"", ""', all
	assert_msg inlist("`subcmd'", "`subcmd_commas'"), msg("Valid subcommands for -estdb- are: `subcmd_list'")
	local subcmd `=proper("`subcmd'")'
	`subcmd' `0'
end
