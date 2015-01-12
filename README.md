
# ESTDB

## Usage

This is an experimental package intended for personal use.

## Installation

```stata
cap ado uninstall estdb
net from https://raw.githubusercontent.com/sergiocorreia/estdb/master/package/
net install estdb
```

## Abstracting

What's the proper level of abstraction for this? 
Ideally we don't want to have to go into the details of VCV footnotes, etc.--and more generally--
we don't care about presentation details, instead just on what we want to report and the program takes care of everything.

However, abstractions leak. A lot. See the -estout- examples. mgroups() should be able to group by e.g. estimation method from e(),
and shouldn't need the pattern suboption.

## Pvalue vs TStat

We *shouldn't care* about point estimates to form beliefs, but if the only thing reported is the beta and the pvalue, then we do.
This is particularly true if the Pvalue is close to zero, as it's non-informative.

Why not just report the Tstat so people can at least do a 66% ci (beta+-tstat).
I see way too many people trying to extract info. from the betas without checking how wide are the CIs (maybe 95% CIs are too harsh, but at least use 66%)

# Complex Scenarios

- Same LHS, but different samples: I need to replace e(depvar)
- Group cols by a category, and label it. Problem: How to set it? (how to map each depvar or regr into a cat?)
- Same LHS but different RHS (e.g. different versions of a control). Instead of having it like an identity matrix (waste of space), just label the difference in the header and rename the vars so they are the same
- What about subheaders?
- In general, what if we just set e.g. headers(method depvar #) -> # is (1), the others are just e(). If the FIRST (besides #) is repeated, group by it (and span by it). If the second is repeated, do the same. But how to set up estout for this?!?

```stata
header(group varname method #)
```


# Estout Tricks

## Add extra cols with labcol2

```stata
labcol2(+ ? + -, title("" Hypothesis))
```

## Add yes/no controls at the bottom
```stata
indicate(rep dummies = _Irep78*)
```

Problem: These don't work well with `areg` and `reghdfe`.

## Add reference categories (or more generally, extra rows)

```stata
refcat(_Idrug_2 "Placebo", label(1))
refcat(weight "Main effects:" turn "Controls:", nolabel)
```

## Match coefs across models

```stata
rename(altmpg mpg)
```

## Within-cell syntax

There is a nice syntax for saying how to allocate stats within cells:

```stata
stats(F p N, layout("@ @" @) fmt(a3 3 a3) labels("F statistic" "Observations"))
```
Basically, quotes are the row delimiters. By using "@" as placeholders, you can add text/format to the cells.

## Arrange models in groups
```stata
mgroups(A B, pattern(1 0 1 0) 
```
## Tips for outputting in other formats

begin, delimited and end control the delimiters in a row. incelldelimiter is within a row. Also see: hlinechar interaction mlabels mgroups numbers abbrev  modelwidth varwidth (span?)

## Author

[Sergio Correia](sergio.correia@gmail.com), Duke University

## To Do List - Features

- [ ] Labels
    - [ ] RHS
    - [ ] LHS
- [ ] Notes
    - [ ] Footnotes
    - [ ] VCV
    - [ ] Significance
- [ ] Group columns
    - [ ] Main groups
    - [ ] Subgroups
    - [ ] asd
- [ ] For later
    - [ ] HTML: use rowspan and colspan attributes for the TH and TD