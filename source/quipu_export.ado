// -------------------------------------------------------------------------------------------------
// QUIPU_EXPORT - Exports the Estimation Tables
// -------------------------------------------------------------------------------------------------
/// SYNTAX
/// quipu export [using] [if] , as(..) [quipu_options] [esttab_options] [estout_options]

capture program drop quipu_export
program define quipu_export
	qui which yaml.ado

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
	include "export/BuildPosthead.ado"
	include "export/BuildPrefoot.ado"
	include "export/BuildVCENote.ado"
	include "export/BuildRHS.ado"
	include "export/BuildStats.ado"
	include "export/BuildFootnotes.ado"
	include "export/BuildPostFoot.ado"
	include "export/AddFootnote.ado"
	include "export/BuildHTML.ado"
	include "export/BuildTEX.ado"
	include "export/BuildPDF.ado"

// Input-Output
	include "export/CompilePDF.ado"
	include "export/RunCMD.ado"
	include "export/SetMetadata.ado"

// Misc
	include "components/Use.ado"
	include "../externals/stata-misc/assert_msg.ado"
