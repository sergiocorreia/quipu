// -------------------------------------------------------------------------------------------------
// ESTDB_EXPORT - Exports the Estimation Tables
// -------------------------------------------------------------------------------------------------
/// SYNTAX
/// estdb export [using] [if] , as(..) [estdb_options] [esttab_options] [estout_options]

capture program drop estdb_export
program define estdb_export
	*preserve
	nobreak {
		Cleanup // Ensure globals start empty
		cap noi break Export `0'
		if (_rc) {
			local rc = _rc
			*BUGBUG Cleanup
			exit `rc'
		}
	}
	*restore
end

// Outer Subroutines
	include "export/Export.ado"
	include "export/Parse.ado"
	include "export/Initialize.ado"
	include "export/Cleanup.ado"
	include "export/LoadEstimates.ado"

// Building Blocks
	include "export/BuildPrehead.ado"
	include "export/BuildHeader.ado"
	include "export/BuildPrefoot.ado"
	include "export/BuildRHS.ado"
	include "export/BuildFootnotes.ado"
	include "export/BuildPostFoot.ado"
	include "export/AddFootnote.ado"
	include "export/BuildHTML.ado"
	include "export/BuildTEX.ado"
	include "export/BuildPDF.ado"

// Input-Output
	include "export/CompilePDF.ado"
	include "export/RunCMD.ado"
	include "export/GetMetadata.ado"
	include "export/SetMetadata.ado"

// Misc
	include "components/Use.ado"
	include "export/metadata.mata"
	include "../externals/stata-misc/assert_msg.ado"
