# Using *quipu* to store and publish estimation results

## Motivation

1) Certain results take a long time to run, and we may want to change estimation tables long after they were run (e.g. different format). 
2) If we have many results, we often want to compare them (by depvar, sample, method, etc.) so we need a good way to *query* those results, using only those that match a condition.
3) We want the table to be readable and polished by default, without tweaking. This also allows us to expose the command to e.g. a markdown extension so tables can be quickly created.

## Usage

First, set the path where the results will be saved. Most of the time you want to use the `replace` option to delete previous estimates saved in that folder. If you want to keep them, just use `append` instead.

```stata
quipu setpath "C:\MyProject\out\results", replace
```
(implementation deatail: this creates a global $quipu_path)

Now save regression, adding notes about the sample, etc.

```stata
sysuse auto
quipu save, notes(sample=foreign logfile="`logfile'"): reg price weight if foreign
quipu save, notes(sample=!foreign logfile="`logfile'"): reg price weight if !foreign
```

After the files are saved, you need to index them:
```stata
quipu index
```
This will create 



## Template ready for copy-paste
```stata
quipu setpath "$OUT/results", append

quipu save, notes(KEY=VAL ...):  CMD

quipu index
update by hand
quipu..

quipu export


```