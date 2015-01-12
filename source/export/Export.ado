capture program drop Export
program define Export
	Parse `0'
	Initialize // Define globals and mata objects (including the metadata)
	qui estdb use `ifcond' // Load selected estimates
	LoadEstimates, header(`header') // Loads estimates and sorte them in the correct order
	BuildHeader, header(`header') // Build header
	li
	de
	estimates dir
	asd
	clear


	* Export table
	ExportInner, filename(`filename') `as' `options'
	
	* Cleanup
	Cleanup
end
