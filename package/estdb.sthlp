{smcl}
{* *! version 0.1.0  17dec2014}{...}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{cmd:estdb} {hline 2}}Estimation Manager - Save to file, manage like database, and export as latex{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax - Saving Estimates and Building an Index}

{p 8 15 2}
{cmd:estdb}
{opt setpath}
[{it:PATH}]
{p_end}
{p 9 11 2}- PATH is where the estimates (.ster files) will be saved, looked up when indexed, or opened when building tables.{p_end}

{p 8 15 2}
{cmd:estdb}
{opt add}
[ , {opt note:s(key1=value1 ...)}
{opt prefix(string)} ]
[ : {it:{help regression command}} ]
{p_end}
{p 9 11 2}- Will save a the estimates in a single file with a .ster extension.{p_end}
{p 9 11 2}- Notes allow the user to later select results based on the value of {it: key}.{p_end}

{p 8 8 2}Advanced: {p_end}
{p 9 11 2}- Prefix will add the text (plus a dash) before the pseudorandom filename
 (a hash of the command string, the number of obs, and the contents of the notes){p_end}
{p 9 11 2}- Without a regression command, the active estimates will be used{p_end}
{p 9 11 2}- The path will be the one set by {it: estdb setpath} (stored in $estdb_path),
 but to override it and the file name, you can set the option {opt filename(string)}.{p_end}

{p 8 15 2}
{cmd:estdb}
{opt view}
[{it:FILENAME}]
{p_end}
{p 9 11 2}- Replays the estimates table; useful when double clicking a .ster file.{p_end}
{p 9 11 2}- FILENAME can be either relative or absolute.{p_end}

{p 8 15 2}
{cmd:estdb}
{opt build_index}
[ , {opt keys(key1 key2 ...)}
{p_end}
{p 9 11 2}- Will index all .ster files located in $estdb_path (and the first level of subfolders).
 It will create an index.dta and varlist_template.dta files, and then call {it: estdb update_varlist}.{p_end}
{p 9 11 2}- The keys can be any of the e() results (notes specified in {it:estdb add} are automatically added,
 as well as four default ones: path, filename, fullpath, time (in %tc format)).{p_end}

{p 8 15 2}
{cmd:estdb}
{opt update_varlist}
{p_end}
{p 9 11 2}- Will create and then merge a tab-separated file where the user can set labels to be used when building the tables. There are four columns:{p_end}
{p 12 14 2} (1) varlabel: the label.{p_end}
{p 12 14 2} (2) footnote: the keyword of the footnote linked to that variable.{p_end}
{p 12 14 2} (3) sort_depvar: the position of the variable in the table (column wise).{p_end}
{p 12 14 2} (4) sort_indepvar: the position of the variable in the table (row wise).{p_end}
{p 9 11 2}- The filename is {it:varlist.tsv}. Only update that file. After updating, run {estdb update_varlist}
again (no need if also running {it: estdb build_index}.{p_end}

{title:Syntax - Selecting Estimates}

{p 8 15 2}
{cmd:estdb}
{opt de:scribe}
[{help if}]
{p_end}
{p 9 11 2}- Report tabulations by -keys- for the estimates that match the condition (tables omitted when a key has only one value in the selection).{p_end}

{p 8 15 2}
{cmd:estdb}
{opt li:st}
[{help if}]
{p_end}
{p 9 11 2}- List results that match a condition.{p_end}

{p 8 15 2}
{cmd:estdb}
{opt br:owse}
[{help if}]
{p_end}
{p 9 11 2}- Browse results that match a condition.{p_end}

{p 8 15 2}
{cmd:estdb}
{opt table}
[{help if}]
{p_end}
{p 9 11 2}- Report raw estimates tables for the estimates that match the condition.{p_end}

{title:Syntax - Building Tables}

{p 8 15 2}
{cmd:estdb}
{opt report}
[{help if}]
{p_end}
{p 9 11 2}- Build pretty tables for the estimates that match the condition.{p_end}
{p 9 11 2}- Tables can be in smcl format (for quick inspection) or latex format.{p_end}
{p 9 11 2}- The detailed syntax is still a work in progress.{p_end}

{title:Syntax - Misc Subcommands}

{p 8 15 2}
{cmd:estdb}
{opt associate}
{p_end}
{p 9 11 2}- Will try to add .ster files to the Windows registry, linking them to the current Stata binary.{p_end}

{p 8 15 2}
{cmd:estdb}
{opt use}
[{help if}]
{p_end}
{p 9 11 2}- This is an internal subcommand that loads the index dataset for the obs. that match the condition{p_end}
