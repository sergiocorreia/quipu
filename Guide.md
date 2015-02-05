# Using *quipu* to store and publish estimation results

## Motivation

1. Certain results take a long time to run, and we may want to change estimation tables long after they were run (e.g. different format). 
2. If we have many results, we often want to compare them (by depvar, sample, method, etc.) so we need a good way to *query* those results, using only those that match a condition.
3. We want the table to be readable and polished by default, without tweaking. This also allows us to expose the command to e.g. a markdown extension so tables can be quickly created.

## Usage

First, set the path where the results will be saved. Most of the time you want to use the `replace` option to delete previous estimates saved in that folder. If you want to keep them, just use `append` instead.

```stata
quipu setpath "C:\MyProject\out\results", replace
```
Now save the regressions, adding notes about the sample, etc.

```stata
sysuse auto
quipu save, notes(sample=foreign logfile="`logfile'"): reg price weight if foreign
quipu save, notes(sample=!foreign logfile="`logfile'"): reg price weight if !foreign
```

After the files are saved, you need to index them:

```stata
quipu index, keys(model)
```
The `keys` option is very useful as it allows us to select what estimates we want to use in a table. In this case, we will be able to use e(model), as well as all the ones set by `notes()` (i.e., sample and logfile).

## Template ready for copy-paste
```stata
quipu setpath "$OUT/results", append

quipu save, notes(KEY=VAL ...):  CMD

quipu index, notes(KEY ...)
update by hand
quipu..

quipu export

## Implementation details

1. `setpath` creates a global $quipu_path
2. Saving an regression creates a .sest file, with filename based on the command, notes, etc. so that if you run the same regr. twice it will overwrite the previous file.
2. `index` just creates an index.dta file with one row for each estimate and one column for each note.

```