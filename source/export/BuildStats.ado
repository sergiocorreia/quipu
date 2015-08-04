capture program drop BuildStats
program define BuildStats
syntax [anything(name=stats equalok everything)],  EXTension(string) [scalebaseline(real 1.0)]
	// [Fmt(string) Labels(string asis)]

	local DEFAULT_STATS_all N
	local DEFAULT_STATS_ols r2 r2_a
	local DEFAULT_STATS_iv underid weakid overid // idp widstat jp
	*local DEFAULT_STATS_fe
	*local DEFAULT_STATS_re

	* If no override, use defaults
	local default "default"
	local use_default : list default in stats
	if (`use_default') {
		local stats : list stats - default
		local morestats `stats'
	}
	if ("`stats'"=="" | `use_default') {
		qui levelsof model, local(models) clean
		local stats `DEFAULT_STATS_all'
		foreach model of local models {
			if ("`DEFAULT_STATS_`model''"!="") {
				local stats `stats' `DEFAULT_STATS_`model''
			}
		}
	}
	if (`use_default') local stats `stats' `morestats'
	if ($quipu_verbose>1) di as text "(stats included: " as result "`stats'" as text ")"

	* List of common stats with their label and desired format
	local labels_N			"Observations"
	local labels_N_clust	"Num. Clusters"
	local labels_df_a		"Num. Fixed Effects"
	local labels_F			"F Statistic"
	local labels_r2		"\(R^2\)"
	local labels_r2_a		"Adjusted \(R^2\)"
	local labels_idp		"Underid. P-val. (KP LM)"
	local labels_widstat	"Weak id. F-stat (KP Wald)"
	local labels_jp		"Overid. P-val (Hansen J)"
	
	local labels_baseline "Mean of Dependent Variable"
	if (`scalebaseline'!=1) local labels_baseline "`labels_baseline' \((\times `scalebaseline')\)"

	local labels_underid_1 "Underidentification test"
	local labels_underid_2 "\enskip \(p \, \) value"

	local labels_weakid_1 "Weak identification F stat."
	local labels_weakid_2 "\enskip 10% maximal IV size"

	local labels_overid_1 "Overidentification J stat."
	local labels_overid_2 "\enskip \(p \, \) value"

	local fmt_N			%12.0gc
	local fmt_N_clust	%12.0gc
	local fmt_df_a		%12.0gc
	local fmt_r2		%6.3f
	local fmt_r2_a		%6.3f
	*local fmt_idp		%6.3fc
	*local fmt_widstat	%6.2fc
	*local fmt_jp		%6.3fc

	local fmt_id0		%2.0f // Number of dof
	local fmt_id1		%5.1f // The Fstats or Chi stats
	local fmt_id2		%5.3f // The p-values

	local fmt_baseline	%6.4g

	local DEFAULT_FORMAT a3

	* Underidentification test (Kleibergen-Paap rk LM statistic) = idstat iddf idp
	* Weak identification test (Kleibergen-Paap rk Wald F statistic) = e(widstat) // stock-yogo?
	* Hansen J statistic (overidentification test of all instruments) =  e(jp)  e(jdf)  e(j)
		// The joint null hypothesis is that the instruments are valid instruments
		// A rejection casts doubt on the validity of the instruments.

	* Parse received fmt and labels, to override defaults
	*foreach cat in fmt labels {
	*	local args `"``cat''"'
	*	while (`"`args'"'!="") {
	*		gettoken key args : args
	*		gettoken val args : args
	*		local `cat'_`key' `val'
	*	}
	*}

	* Parse stats
	local expanded_stats
	foreach stat of local stats {

		* Magical stats
		if inlist("`stat'", "overid", "weakid", "underid") {
			local statlabels `"`statlabels' "`labels_`stat'_1'" "`labels_`stat'_2'""'

			if ("`stat'"!="weakid") local statformats `"`statformats' `fmt_id0' `fmt_id1' `fmt_id2'"'
			if ("`stat'"=="weakid") local statformats `"`statformats' `fmt_id1' `fmt_id1'"'

			if ("`stat'"!="weakid") local exp "\(\chi^2(@){=}@\)"
			if ("`stat'"=="weakid") local exp "@"

			local layout = cond("`extension'"=="html", "`exp'", "\multicolumn{1}{r}{`exp'}")
			local layouts = `"`layouts' "`layout'""'
			local layout = cond("`extension'"=="html", "@", "\multicolumn{1}{r}{@}")
			local layouts = `"`layouts' "`layout'""'


			if ("`stat'"=="overid") local expanded_stats `expanded_stats' jdf  j jp
			if ("`stat'"=="underid") local expanded_stats `expanded_stats' iddf idstat idp
			if ("`stat'"=="weakid") local expanded_stats `expanded_stats' widstat stock_yogo
		}
		else {
			local expanded_stats `expanded_stats' `stat'
			local statlbl = cond(`"`labels_`stat''"'!="", `"`labels_`stat''"', "`stat'")
			local statfmt = cond(`"`fmt_`stat''"'!="", `"`fmt_`stat''"', "`DEFAULT_FORMAT'")
			local statlabels `"`statlabels' "`statlbl'""'
			local statformats `"`statformats' `statfmt'"'
			local layout = cond("`extension'"=="html", "@", "\multicolumn{1}{r}{@}")
			local layouts = `"`layouts' "`layout'""'
		}
	}

	global quipu_stats `"stats(`expanded_stats', fmt(`statformats') labels(`statlabels') layout(`layouts') )"'
end
