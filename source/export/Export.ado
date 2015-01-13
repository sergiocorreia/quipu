capture program drop Export
program define Export
	Parse `0'
	Initialize, metadata(`metadata') // Define globals and mata objects (including the metadata)
	qui estdb use `ifcond' // Load selected estimates
	LoadEstimates, header(`header') // Loads estimates and sorte them in the correct order
	BuildHeader, header(`header') // Build header and saves it in $estdb_header
	clear

	* Export table
	ExportInner, filename(`filename') latex_engine(`latex_engine') `html' `tex' `pdf' `options'
	
	* Cleanup
	Cleanup
end
