capture program drop BuildHTML
program define BuildHTML
syntax, filename(string) [VIEW] [*]

  * PDF preface and epilogue
  qui findfile quipu-top.html.ado
  local fn_top = r(fn)
  qui findfile quipu-bottom.html.ado
  local fn_bottom = r(fn)

  * Substitute characters conflicting with html
  local substitute < &lt; > &gt; & &amp;

  local cmd esttab quipu* using "`filename'.html"
  local html_opt top(`fn_top') bottom(`fn_bottom')
  RunCMD `cmd', `html_opt' `options'
  *di as text `"(output written to {stata "shell `filename'.html":`filename'.html})"'
  if ("`view'"!="") RunCMD shell `filename'.html

	di as error "NOT YET SUPPORTED"
	error 1234
end


/* Primer on HTML Tables

# TLDR
Tables contain "table rows", that contain "table data" or "table headings"

# Template

<table ...>
	<tr>
		<td> ... </td>
		...
	</tr>
	...
</table>

# Attributes

## Borders

EG: border="1". But it's better to use CSS:

table, th, td {
    border: 1px solid black;
}

If you want the borders to collapse into one border, add CSS border-collapse:

table, th, td {
    border: 1px solid black;
    border-collapse: collapse;
}

## Padding
http://www.w3schools.com/html/tryit.asp?filename=tryhtml_table_cellpadding

## Add format just to headers:
th {
    text-align: left;
}

# BOrder spacing

Border spacing specifies the space between the cells.
table {
    border-spacing: 5px;
}

Note: If the table has collapsed borders, border-spacing has no effect.

## Multicolumn

EG: colspan="2" for each th/td ; and also rowspan 

## Caption
<table style="width:100%">
  <caption>Monthly savings</caption>
  ...

## Misc

Add ID to TABLE and set a special style: id="t01"
Then:
table#t01 {
    width: 100%; 
    background-color: #f1f1c1;
}

thead
tbody
tfoot
col
colgroup


*/
