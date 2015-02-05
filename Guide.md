# Using *quipu* to store and publish estimation results

## Motivation

1) Certain results take a long time to run, and we may want to change estimation tables long after they were run (e.g. different format). 
2) If we have many results, we often want to compare them (by depvar, sample, method, etc.) so we need a good way to *query* those results, using only those that match a condition.
3) We want the table to be readable and polished by default, without tweaking. This also allows us to expose the command to e.g. a markdown extension so tables can be quickly created.

## Usage

First, set the path where

Save a regression, adding notes about the sample, etc.
```stata
quipu save
```