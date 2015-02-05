Estout is quite complex; these are some notes on how to call it from quipu report.
Source: http://repec.org/bocode/e/estout/hlp_estout.html#ref

# Usage
`estout quipu* using OUTPUTFILE.EXT , OPTIONS`

# Options

## Cells
- Syntax: `cells(ROW1 ROW2 ..)`, where rows with 2+ items are grouped with quotes or parens. EG: cells(b "se t") will have the betas by themselves and se/t sharing a row.
- Items: b se t p ci ci_l ci_u var . _star _sign _sigsign
- & combines elements in a single cell.
- Any other item is looked in e(..). item[#] means e(item)[#]
- Suboptions: Each item can have suboptions e.g. b(..)
    + star
    + fmt(%..)
    + label(STR)
    + par par(l) par(r) nopar
    + vacant(str): Replacement if missing
    + drop(droplist)
    + keep(keeplist)
    + pattern(pat): ??
    + pvalue(name): ??
    + abs: use absolute Tstats

## Stats
- Syntax : `stats(scalarlist, subopts)`
- Suboptions:
    + fmt(..)
    + labels(strlist, label_subopts)
    + star(..)
    + layout(ARRAY) ? @ is placeholder, like map/transform
    + 

## Significance Stars
- starlevels(symbol # ...): # between 0,1 , listed in descending order
- stardrop (drop star for indiv coefs)
- starkeep
- stardetach (show in their own column)


## Layout
- varwidth(#) width of first column
- model:width(# ..) width of other columns
- nountack unstack: join eqns of multiple eq models
- begin(str): text beginning the table rows
- delim:iter(str): column delim
- end(str)
- incell:delim(str): delimiter within cell
- lz: Print leading zero of fixed format numbers in (-1,1)
- extracols(numlist): add extra empty columns
- sub:stitute(from to ..): apply substitutions at the very end

## Labeling
- label: use varlabels; note that we can't use those b/c variables don't exist
- abbrev: abbrev long names and labels
- wrap: wrap long labels if possible
- inter:action(str): operator for interactions
- title(str): table title
- note(str): table note
- [no]legend: Significance symbols
- prehead(strlist): Text before table heading
- posthead(), prefoot(), postfoot()
- hl:inechar(str): look of @hline
- varl:ables(matchlist, subopts)
    + blist(matchlist): add prefixes to some rows?
    + elist(matchlist): add suffixes..
    + All label subopts
- labcol2(strlist, subopts): Add second label column
    + title(strlist): col title
    + width(#): col width
- refcat(matchlist, subopts): Add a row, usually indicating the baseline or separating lists of coefs.
    + label(string) nolable below
- mlabels(strlist, subopts): label the modes
    + depvars titles numbers (accept no prefix) label_subopts
- collabel(strlist, subopts): label cols within models
    + label_subopts
- eqlabels(strlist, subopts): label eqs
    + no:merge label_subopts
- mgroups(strlist, subopts): define and label GROUPS OF MODELS
    + pattern(pat) label_subopts
- numbers numbers(l|r) nonumbers: row with model numbers

### Label Suboptions
- none: no labels
- prefix(str)
- suffix(str)
- begin(strlist)
    + first nofirst
- end(strlist)
    + last nolast
- replace: replace global begin() end()
- span nospan: span cols if appropiate
- erepeat(str): add a "span" suffix
- lhs(str): label the table left stub

## Output
- replace
- append
- type: show in result windows
- showtabs (show tabs as <T>)
- top:file(fn) insert fn above
- bottom:file(fn) insert fn below

## Extra

- drop(droplist)
- omitted noomitted
- baselevels nobaselevels
- keep(keeplist)
- order(orderlist)
- indicate(groups) indicate(groups, labels(Y N))
- rename(old new ...)
- equations(eqmatchlist) ??
- dropped(str)
- level(#): for the CI

### Style

Tex, html, smcl

### Margins related
- margin
- discrete
- meqs(eqlist)

## Calling estout from acad markdown:

In the metadata, we set
estimates folder? NO, always called ESTIMATES
stata path?? or just assume stata opens when we run the dofile??

- estimates-template: template.txt
- estimates-update: false
- estimates-options: .. (ON TOP OF TEMPLATE.. NEEDED? OR AS ALTERNATIVE?)

bla bla bla bla, as seen in table-robust-iv

~~~ estimates
- name: robust-iv
- title: Varying the Radius
- condition: logfile=="foobar" & radius!=.
- options: ... (on top of the default)
- orientation: portrait | landscape
- fontsize: 4 # 1 2 3 4 ..
- clearpage = True
~~~

This will
1) build the cmd: quipu using NAME if CONDITION, DEFOPT OPTIONS title(...)
2) Automatically create the label ESTIMATES:ROBUST-IV (in lowercase)

At the end, we will end up with a DO FILE in the ./estimates folder, which we will run if estimates-update is TRUE

all the quipu commands will create .tex files with the expected names

then when stata is done and exits, we will go back to the pandoc filter and insert the .tex files

It would be cool if we can also create files ready for .doc and .html (future..)

Also include an option in the metadata to put all the tables at the bottom
- estimates-are-draft: true

When a new file is created, autocomplete the metadata so its easy to remember (i.e. with a gist or whatever)

