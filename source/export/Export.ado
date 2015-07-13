capture program drop Export
program define Export
	Parse `0'
	
	Initialize, ext(`ext') metadata(`metadata') `verbose' // Define globals and mata objects (including the metadata)
	Use `ifcond' // Load selected estimates
	LoadEstimates `header', indicate(`indicate') // Loads estimates and sort them in the correct order
	BuildPrehead, ext(`ext') colformat(`colformat') title(`title') label(`label') ifcond(`ifcond') orientation(`orientation') size(`size')	
	BuildHeader `header', headerhide(`headerhide') ext(`ext') fmt(`fmt') // Build header and saves it in $quipu_header (passed to posthead)
	BuildStats `stats', ext(`ext')
	BuildPrefoot, ext(`ext') // This creates YES/NO for indicators, so run this before clearing the data!
	BuildVCENote, vcenote(`vcenote') // This clears the data!
	clear // Do after (BuildHeader, BuildStats). Do before (BuildRHS)
	BuildRHS, ext(`ext') rename(`rename') drop(`drop') // $quipu_rhsoptions -> rename() drop() varlabels() order()
	BuildFootnotes, ext(`ext') notes(`notes') stars(`stars') // Updates $quipu_footnotes
	BuildPostfoot, ext(`ext') orientation(`orientation') size(`size') `pagebreak'  // Run *AFTER* building $quipu_footnotes
	BuildPosthead, ext(`ext')

	if ($quipu_verbose>1) local noisily noisily
	local prepost prehead(`"$quipu_prehead"') posthead(`"${quipu_header}${quipu_posthead}"') prefoot(`"$quipu_prefoot"') postfoot(`"$quipu_postfoot"')
	estfe quipu* // , labels(x#y "X times Y") // no need to do -estfe quipu* , restore
	local base_opt replace `noisily' $quipu_rhsoptions $quipu_starlevels mlabels(none) nonumbers `cellformat' ${quipu_stats} `prepost' indicate(`r(indicate_fe)')
	if ("`ext'"=="html") BuildHTML, filename(`filename') `view' `base_opt' `options' // style(html)
	if ("`ext'"=="pdf") BuildPDF, filename(`filename') engine(`engine') `view' `base_opt' `options'
	if ("`ext'"=="tex") BuildTEX, filename(`filename') `base_opt' `options'  // Run after PDF so it overwrites the .tex file
	
	Cleanup
end

