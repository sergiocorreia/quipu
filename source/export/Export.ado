capture program drop Export
program define Export
	Parse `0'
	
	Initialize, metadata(`metadata') // Define globals and mata objects (including the metadata)
	Use `ifcond' // Load selected estimates
	LoadEstimates `header' // Loads estimates and sort them in the correct order

	BuildPrehead, colformat(`colformat') title(`title') label(`label') ifcond(`"`ifcond'"') orientation(`orientation') size(`size')	
	BuildHeader `header' // Build header and saves it in $quipu_header (passed to posthead)
	BuildStats `stats'
	BuildVCENote, vcenote(`vcenote') // This clears the data!
	clear // Do after (BuildHeader, BuildStats). Do before (BuildRHS)
	BuildRHS, rename(`rename') drop(`drop') // $quipu_rhsoptions -> rename() drop() varlabels() order()
	BuildPrefoot
	BuildPostfoot, orientation(`orientation') size(`size') `pagebreak'
	BuildFootnotes, notes(`notes') stars(`stars') // Updates $quipu_footnotes

	if ($quipu_verbose>1) local noisily noisily
	local prepost prehead($quipu_prehead) posthead($quipu_header) prefoot($quipu_prefoot) postfoot($quipu_postfoot)
	local base_opt `noisily' $quipu_rhsoptions $quipu_starlevels mlabels(none) nonumbers `cellformat' ${quipu_stats} `prepost'
	if ("`html'"!="") BuildHTML, filename(`filename') `base_opt' `options'
	if ("`pdf'"!="") BuildPDF, filename(`filename') latex_engine(`latex_engine') `view' `base_opt' `options'
	if ("`tex'"!="") BuildTEX, filename(`filename') `base_opt' `options'  // Run after PDF so it overwrites the .tex file
	
	Cleanup
end
