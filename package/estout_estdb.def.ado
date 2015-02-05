* Default Styles for -quipu.ado-
* Based on estout_mystyle.def, version 1.1.0  02jun2014  Ben Jann
* Source: http://fmwww.bc.edu/repec/bocode/e/estout_mystyle.def
* Note: only comments allowed are: *, // and ///
****************************************************************************************************

// parameter statistics options

*cells              [...] //specify the array without suboptions, e.g.: b se

*b_star             star  //a similar set of suboptions may be specified for 
*b_fmt              [...] //all other parameter statistics
*b_label            [...]
*b_par              [...]
*b_vacant           [...]
*b_keep             [...]
*b_drop             [...]
*b_pattern          [...]

*t_abs              abs   //-abs- suboption only available for t-stats

*drop               [...]
omitted            omitted
baselevels         baselevels
*keep               [...]
*order              [...]
*indicate           [...]
indicatelabels     Yes No
*equations          [...]
*eform              [...] //specify "eform" (without quotes) or a pattern of 0's and 1's
*transform          [...]
*transformpattern   [...]
*margin             [...] //specify one of: margin, u, c, p 
discrete           " (d)" for discrete change of dummy variable from 0 to 1
*meqs               [...]
*dropped            [...]

// summary statistics options

*stats              [...] //specify the scalar list without suboptions
*statsfmt           [...]
*statslabels        [...]
*statslabelsnone    none
*statslabelsprefix  [...]
*statslabelssuffix  [...]
*statslabelsbegin   [...]
*statslabelsend     [...]
statslabelsfirst   first
statslabelslast    last
*statsstar          [...]

// significance stars options

*starlevels         * 0.05 ** 0.01 *** 0.001
*stardetach         stardetach
*starkeep           [...]
*stardrop           [...]

// layout options

varwidth           0
modelwidth         0
*abbrev             abbrev
*wrap               wrap
*unstack            unstack
*begin              [...]
delimiter          _tab
incelldelimiter    " "
*end                [...]
*dmarker            [...]
*msign              [...]
lz                 lz
*extracols          [...]
*substitute         [...]

// labeling options

*legend             legend
prehead            [...]
posthead           [...]
*prefoot            [...]
*postfoot           [...]
*hlinechar          [...]
*label              label
interaction         " # "

*varlabels          [...]
*varlabelsnone      none
*varlabelsprefix    [...]
*varlabelssuffix    [...]
*varlabelsbegin     [...]
*varlabelsend       [...]
*varlabelsblist     [...]
*varlabelselist     [...]
varlabelsfirst     first
varlabelslast      last

*refcat             [...]
refcatlabel        ref.
*refcatbelow        below

*mlabels            [...] //a similar set of options may be specified 
*mlabelsnone        none  //for collabels, eqlabels, and mgroups
*mlabelsprefix      [...]
*mlabelssuffix      [...]
*mlabelsspan        span
*mlabelsbegin       [...]
*mlabelsend         [...]
*mlabelserepeat     [...]

*mlabelsnumbers     numbers //-numbers- suboption only available in mlabels()
*mlabelsdepvars     depvars //-depvars- suboption only available in mlabels()
*mlabelstitles      titles  //-titles- suboption only available in mlabels()

*mgroupspattern     [...] //-pattern- suboption only available in mgroups()

eqlabelsfirst     first
eqlabelslast      last

*numbers            [...]

*labcol2            [...]
*labcol2title       [...]
*labcol2width       0

// output options

*replace            replace
*append             append
*type               type
*showtabs           showtabs

****************************************************************************************************
*begin
*html: <tr><td>
*
*delim
*tab: _tab
*fixed: " "
*tex: &
*html: </td><td>
*
*end
*tex: \\
*html: </td></tr>
*
*varwidth
*tab: 0
*others: 12 (or 20 if -label- is on)
*
*modelwidth
*tab: 0
*others: 12
*
*abbrev
*fixed: on
*others: off
