capture program drop Export
program define Export

	Parse `0'
	Initialize
	qui estdb use `ifcond'
	LoadEstimates
	asd
	* Export table
	ExportInner, filename(`filename') `as' `options'
	
	* Cleanup
	Cleanup
end
