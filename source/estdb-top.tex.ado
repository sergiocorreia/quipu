\documentclass[12pt,letterpaper]{article} % ,draft %% Draft warns of boxes and hides figures

% Preamble
	%% Tables %%
	\usepackage{longtable} %% Adds -longtable- environment; similar to -tabular- but with multipage tables
	\usepackage{booktabs} %% Improve table format: adds -toprule-, -midrule-, -bottomrule-
	\usepackage{pdflscape} %% Improved -lscape-: Allows rotation of page contents, including when viewing the pdf
	\usepackage{geometry} %% Allows -newgeometry- command, to change geometry mid-document (useful with a huge table)
	\usepackage{threeparttable} %% Adds titles and notes to tables
	\usepackage{threeparttablex} %% Extends -threeparttable- to work with -longtable-. Creates the ThreePartTable, TableNotes and insertTableNotes commands/environments
	\usepackage{dcolumn} %% Estout suggests this to improve alignment: http://repec.org/bocode/e/estout/esttab.html
	\usepackage{array} %% The new column types below require arraybackslash

	%% Allow text wrapping in multicolumn
	%% See http://tex.stackexchange.com/questions/115668/wrapping-text-in-multicolumn
	\newcolumntype{L}[1]{>{\raggedright\let\newline\\\arraybackslash\hspace{0pt}}m{#1}}
	\newcolumntype{C}[1]{>{\centering\let\newline\\\arraybackslash\hspace{0pt}}m{#1}}
	\newcolumntype{R}[1]{>{\raggedleft\let\newline\\\arraybackslash\hspace{0pt}}m{#1}}

	%% Improve ThreePartTable
	\newcommand\Note[1]{\parskip 0pt \begingroup \par \parshape0 \textsc{Note}.--- #1  \par \endgroup }
	\newcommand\Source[1]{\parskip 0pt \begingroup \par \parshape0 \textsc{Source}.--- #1 \par \endgroup }
	\renewcommand{\TPTminimum}{\linewidth} %% Give full width to threeparttable

	%% Used by -esttab- in the significance footnotes
	\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}

% Body (just the table)
\begin{document}
