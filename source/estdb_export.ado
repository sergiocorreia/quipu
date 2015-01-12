* makethesis.py tables.ado (en aug) filter.py (en Research/latex/pandoc)

// -------------------------------------------------------------------------------------------------
// ESTDB_EXPORT - Exports the Estimation Tables
// -------------------------------------------------------------------------------------------------
/// SYNTAX
/// estdb export [using] [if] , as(..) [estdb_options] [esttab_options] [estout_options]

capture program drop estdb_export
program define estdb_export
	nobreak {
		cap noi break Export `0'
		if (_rc) {
			local rc = _rc
			*BUGBUG Cleanup
			exit `rc'
		}
	}
end

// Outer Subroutines
	include "export/Export.ado"
	include "export/Parse.ado"
	include "export/Initialize.ado"
	include "export/Cleanup.ado"
	include "export/LoadEstimates.ado"
// Main Subroutine
	include "export/ExportInner.ado"
// Building Blocks
	include "export/BuildHeader.ado"
	include "export/ProcessLHS.ado"
	include "export/ProcessRHS.ado"
	include "export/Prehead.ado"
	include "export/Footnotes.ado"
	include "export/AddFootnote.ado"
// Input-Output
	include "export/CompilePDF.ado"
	include "export/RunCMD.ado"
	include "export/GetMetadata.ado"
	include "export/SetMetadata.ado"
// Misc
	include "export/metadata.mata"
	include "../externals/stata-misc/assert_msg.ado"
