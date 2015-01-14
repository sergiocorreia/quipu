capture program drop Export
program define Export
	Parse `0'
	
	Initialize, metadata(`metadata') // Define globals and mata objects (including the metadata)
	Use `ifcond' // Load selected estimates
	LoadEstimates, header(`header') // Loads estimates and sort them in the correct order
	
	BuildPrehead, colformat(`colformat') title(`title') label(`label') ifcond(`"`ifcond'"') orientation(`orientation') size(`size')
	BuildHeader, header(`header') // Build header and saves it in $estdb_header (passed to posthead)
	clear // Do after -BuildHeader- and before -BuildRHS-
	BuildRHS, rename(`rename') drop(`drop') // $estdb_rhsoptions -> rename() drop() varlabels() order()
	BuildPrefoot
	BuildPostfoot, orientation(`orientation') size(`size') `pagebreak'
	BuildFootnotes, notes(`notes') vcnote(`vcnote') // Updates $estdb_footnotes

	if ("`html'"!="") BuildHTML, filename(`filename') `options'
	if ("`pdf'"!="") BuildPDF, filename(`filename') latex_engine(`latex_engine') `view' `options'
	if ("`tex'"!="") BuildTEX, filename(`filename') `options'  // Run after PDF so it overwrites the .tex file
	
	Cleanup
end
