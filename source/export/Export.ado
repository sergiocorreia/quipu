capture program drop Export
program define Export
	Parse `0'
	
	Initialize, metadata(`metadata') // Define globals and mata objects (including the metadata)
	Use `ifcond' // Load selected estimates
	LoadEstimates `header' // Loads estimates and sort them in the correct order

	BuildPrehead, ext(`ext') colformat(`colformat') title(`title') label(`label') ifcond(`"`ifcond'"') orientation(`orientation') size(`size')	
	BuildHeader `header', ext(`ext') fmt(`fmt') // Build header and saves it in $quipu_header (passed to posthead)
	BuildStats `stats'
	BuildVCENote, vcenote(`vcenote') // This clears the data!
	clear // Do after (BuildHeader, BuildStats). Do before (BuildRHS)
	BuildRHS, rename(`rename') drop(`drop') // $quipu_rhsoptions -> rename() drop() varlabels() order()
	BuildPrefoot
	BuildPostfoot, ext(`ext') orientation(`orientation') size(`size') `pagebreak'
	BuildFootnotes, notes(`notes') stars(`stars') // Updates $quipu_footnotes

	if ($quipu_verbose>1) local noisily noisily
	local prepost prehead($quipu_prehead) posthead($quipu_header) prefoot($quipu_prefoot) postfoot($quipu_postfoot)
	local base_opt replace `noisily' $quipu_rhsoptions $quipu_starlevels mlabels(none) nonumbers `cellformat' ${quipu_stats} `prepost'
	if ("`ext'"=="html") BuildHTML, filename(`filename') `view' `base_opt' // `options' style(html)
	if ("`ext'"=="pdf") BuildPDF, filename(`filename') latex_engine(`latex_engine') `view' `base_opt' `options'
	if ("`ext'"=="tex") BuildTEX, filename(`filename') `base_opt' `options'  // Run after PDF so it overwrites the .tex file
	
	Cleanup
end
