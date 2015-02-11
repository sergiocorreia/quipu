# Using *quipu* to store and publish estimation results

## Motivation

1. Certain results take a long time to run, and we may want to change estimation tables long after they were run (e.g. different format). 
2. If we have many results, we often want to compare them (by depvar, sample, method, etc.) so we need a good way to *query* those results, using only those that match a condition.
3. We want the table to be readable and beautiful by default, without tweaking. This also allows us to expose the command to e.g. a markdown extension so tables can be quickly created.

## Usage

### Path

First, set the path where the results will be saved. Most of the time you want to use the `replace` option to delete previous estimates saved in that folder. If you want to keep them, just use `append` instead.

```stata
quipu setpath "C:\MyProject\out\results", replace
```

### Saving Estimates

Now save the regressions, adding notes about the sample, etc.

```stata
sysuse auto
quipu save, notes(sample=foreign logfile="`logfile'"): reg price weight if foreign
quipu save, notes(sample=!foreign logfile="`logfile'"): reg price weight if !foreign
```

### Indexing Estimates

After the files are saved, you need to index them:

```stata
quipu index, keys(model)
```
The `keys` option is very useful as it allows us to select what estimates we want to use in a table. In this case, we will be able to use e(model), as well as all the ones set by `notes()` (i.e., sample and logfile).

Sometimes you may want to index estimates by more than just names in e(). One option is to do complex expressions within `notes()`, but a better one is to use "brackets"

```stata
quipu index, keys(model) {
	gen byte subsample = strpos(cmdline, " if ") > 0
    gen byte horizon = real(regexs(2)) if regexm(depvar, "will_(default|late)([0-9]+)")
}
```

In this case, the code inside brackets will be run on the index dataset after all colums are added (so we can't operate on e(), but we could store the e()s and then drop those that we don't need).

Note: the option -test- will only load the first 10 estimates per folder; use it for debugging if you have too many estimates.

### Adding labels, ordering, footnotes, etc.

After creating the index, two files will be created: `varlist.tsv` and `metadata.txt`.

The first file is a tab-delimited file. It has 5 columns of interest:

1. Varnames of all relevant variables (depvars, indepvars, clustervars, etc.).
2. Varlabels that you should fill (you can use latex math syntax with "\( )\" ).
3. Names of footnotes associated to a variable (useful for clarifying definitions).
4. Order of the variable in case it appears as a depvar (low number=left, high number=right)
5. Order of the variable in case it appears as an indepvar (lower=up higher=down).

The second file is a markdown file with metadata. Note that:

1. Lines started with * will be ignored
2. The footnotes section lists footnotes with "name: definition" in each line.
3. The groups section has the names for groups of columns (REVIEW)
4. The globals section contains global variables that can be referred to when writing footnotes for the table
5. Subgroups (REVIEW)

### Updating the index

After manually editing the two label/metadata files, you need to update the index:

```stata
quipu update
```

### (Optional) Inspecting Results

Before creating the tables you may want to inspect the results. How many fit each condition, etc. For instance,

```stata
quipu tabulate if model=="ols" & depvar=="price"
```

The command above will show how many estimates match the conditions, and tabulate what other conditions vary within those (so you could further narrow down the selection).

Other useful subcommands with the same syntax are `list` and `browse` (self explanatory), `table` (which does a quick but ugly table of results), and `replay` (which replays all estimates one after another).

### Creating Tables

You can create and export tables as HTML, Tex files (to be included in another tex file), and PDFs. You can also customize the title, label, headers, footnotes, reported stats, etc.

The full syntax is

```stata
quipu export myfile.fmt [if] , [common_opt] [adv_opt] [pdf_opt] [misc_opt] [esttab_opt]
```
Options:

* Common: `title() label() header() notes() stats()`
* Advanced: `colformat() vcenote() rename() drop() metadata() stars() cellformat()`
* Misc: `verbose(#) view engine(xelatex|pdflatex)`
* PDF: `size(#) orientation(portrait|landscape) pagebreak`
* Esttab: anything else will be passed through to esttab/estout.

Note that many of these options are magic-like and do a lot of things under the hood. For instance,

* The output format is inferred from the extension. Valid extensions are html, tex and pdf.
* Headers allow very easy grouping of models. EG: `header(group varname method #)`
* VCE notes are autoinferred from the estimates (e.g. clustering, robust SEs)
* rename() and drop() are actually doing regex matching

### Noting FEs

(not coded yet)
There are three ways fixed effects may appear:
1. Implicly in xtreg, fe (search for the tsvars)
2. Within absorb() in either areg() or reghdfe()
3. As dummies in i##.varname

The indicate() option helps with the third one only, and may also conflict with how -quipu- works.

The soln. is to extend postfoot() or prefoot() to manually add the lines (like BuildHeader does). Now, what should be the syntax?

* Just use -indicate- as option
* And in metadata.txt , add the keys `indicate_yes` and `indicate_no`.
* Also in metadata add a group for the labels of the absorbed vars (maybe call it -indicate-)
 


## Summary

To recap, these are the steps:

1. Set the path with `setpath`
2. Save regressions with `save`
3. Build index with `index`
4. Edit labels, footnotes, etc.
5. Update index with `update`
6. Export tables with `export`

You can also run some subcommands to inspect the index:

1. `tabulate`
2. `list`
3. `browse`
4. `table`
5. `replay`

And there are also seldom-used subcommands:

1. `associate`
2. `view`
3. `use`

## Template ready for copy-paste
```stata
quipu setpath "$OUT/results", append

quipu save, notes(KEY=VAL ...):  CMD

quipu index, notes(KEY ...)
update by hand
quipu..

quipu export
```

## Implementation details

1. `setpath` creates a global $quipu_path
2. `save` creates a .sest file, with the filename based on the command, notes, etc. so that if you run the same regr. twice it will overwrite the previous file.
2. `index` just creates an index.dta file with one row for each estimate and one column for each note.
3. `index' with brackets uses `qui disp _request2(_curline)` under the hood, stopping when `strpos(trim(LINE),"}")==1`
4. Most of the subcommands (export, tabulate, etc.) depend on the hardcoded path of the estimates. To change it, use the option `moved(FROM TO)` that will perform a quick replacement in the path string.
