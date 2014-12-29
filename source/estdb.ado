// -------------------------------------------------------------------------------------------------
// ESTDB - Save and manage regr. estimates and export tables via -estout-
// -------------------------------------------------------------------------------------------------
capture program drop estdb
program define estdb
	local subcmd_list1 associate setpath add build_index update_varlist view
	local subcmd_list2 use tabulate list browse table export replay

	* Remove subcmd from 0
	gettoken subcmd 0 : 0, parse(" ,:")

	* Expand abbreviations and call appropiate subcommand
	if (substr("`subcmd'", 1,3)=="tab" & "`subcmd'"!="table") local subcmd "tabulate"
	if (substr("`subcmd'", 1,2)=="br") local subcmd "browse"
	if (substr("`subcmd'", 1,2)=="li") local subcmd "list"
	if (substr("`subcmd'", 1,5)=="build") local subcmd "build_index"
	if (substr("`subcmd'", 1,6)=="update") local subcmd "update_varlist"

	local subcmd_commas1 : subinstr local subcmd_list1 " "   `"", ""', all
	local subcmd_commas2 : subinstr local subcmd_list2 " "   `"", ""', all
	assert_msg inlist("`subcmd'", "`subcmd_commas1'") | inlist("`subcmd'", "`subcmd_commas2'"), ///
	 	msg("Valid subcommands for -estdb- are: " as input "`subcmd_list1' `subcmd_list2'")
	local subcmd `=proper("`subcmd'")'
	`subcmd' `0'
end

	include "components/Associate.ado"
	include "components/Setpath.ado"
	include "components/Add.ado"
	include "components/Build_Index.ado"
	include "components/Update_Varlist.ado"
	include "components/View.ado"
	include "components/Use.ado"
	include "components/List.ado"
	include "components/Browse.ado"
	include "components/Tabulate.ado"
	include "components/Replay.ado"
	include "components/Table.ado"
	include "components/Export.ado"
	include "../externals/stata-misc/assert_msg.ado"
