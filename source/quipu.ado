// -------------------------------------------------------------------------------------------------
// QUIPU - Save and manage regr. estimates and export tables via -estout-
// -------------------------------------------------------------------------------------------------
capture program drop quipu
program define quipu
	local subcmd_list1 associate setpath save index update_varlist view
	local subcmd_list2 use tabulate list browse table export replay

	* Remove subcmd from 0
	gettoken subcmd 0 : 0, parse(" ,:")

	* Expand abbreviations and call appropiate subcommand
	if (substr("`subcmd'", 1,3)=="tab" & "`subcmd'"!="table") local subcmd "tabulate"
	if (substr("`subcmd'", 1,2)=="br") local subcmd "browse"
	if (substr("`subcmd'", 1,2)=="li") local subcmd "list"
	if (substr("`subcmd'", 1,5)=="build") local subcmd "index"
	if (substr("`subcmd'", 1,6)=="update") local subcmd "update_varlist"

	local subcmd_commas1 : subinstr local subcmd_list1 " "   `"", ""', all
	local subcmd_commas2 : subinstr local subcmd_list2 " "   `"", ""', all
	assert_msg inlist("`subcmd'", "`subcmd_commas1'") | inlist("`subcmd'", "`subcmd_commas2'"), ///
	 	msg("Valid subcommands for -quipu- are: " as input "`subcmd_list1' `subcmd_list2'")
	local subcmd `=proper("`subcmd'")'

	* Special case for Save to deal with multiple estimates
	if ("`subcmd'"=="Save") {
		`subcmd' `0'
		local estimates "`e(stored_estimates)'"
		local prev_filename "`e(filename)'"
		assert "`prev_filename'"!=""

		* Add filename carefully
		cap _on_colon_parse `0'
		if !_rc {
			local cmd `": `s(after)'"'
			local 0 `s(before)'
		}
		syntax , [PREFIX(string) FILENAME(string)] [NOTEs(string)]
		* We will ignore prefix() and the contents of filename()

		foreach estimate of local estimates {
			estimates restore `estimate'
			reghdfe // bugbug
			`subcmd', filename("`prev_filename'") append notes(`notes') `cmd'
			dir F:\CreditCards\out\Regression\Individuals_Debtors_Full\
		}
		exit
	}

	if ("`subcmd'"=="Export") local subcmd quipu_export
	`subcmd' `0'
end

	include "components/Associate.ado"
	include "components/Setpath.ado"
	include "components/Save.ado"
	include "components/Index.ado"
	include "components/Update_Varlist.ado"
	include "components/View.ado"
	include "components/Use.ado"
	include "components/List.ado"
	include "components/Browse.ado"
	include "components/Tabulate.ado"
	include "components/Replay.ado"
	include "components/Table.ado"
	include "../externals/stata-misc/assert_msg.ado"
