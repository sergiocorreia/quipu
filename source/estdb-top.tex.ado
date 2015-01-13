\documentclass[12pt,letterpaper]{article} % ,draft %% Draft warns of boxes and hides figures

%% Table-Specific Preamble
	
	%% Imports
	\usepackage{longtable} %% Adds -longtable- environment; similar to -tabular- but with multipage tables
	\usepackage{booktabs} %% Improve table format: adds -toprule-, -midrule-, -bottomrule-
	\usepackage{pdflscape} %% Improved -lscape-: Allows rotation of page contents, including when viewing the pdf
	\usepackage{threeparttable} %% Adds titles and notes to tables
	\usepackage{threeparttablex} %% Extends -threeparttable- to work with -longtable-. Creates the ThreePartTable, TableNotes and insertTableNotes commands/environments
	\usepackage{dcolumn} %% Estout suggests this to improve alignment: http://repec.org/bocode/e/estout/esttab.html
	\usepackage{array} %% The new column types below require arraybackslash
	\usepackage{ragged2e} %% \raggedright used in table footnotes breaks hyphenation
	\usepackage[labelfont=bf,font=bf]{caption} %% Provides -captionsetup- http://ctan.mackichan.com/macros/latex/contrib/caption/caption-eng.pdf
	\usepackage{comment} %% Allow comment blocks around the tables, for documentation

	%% Allow text wrapping in multicolumn
	%% See http://tex.stackexchange.com/questions/115668/wrapping-text-in-multicolumn
	\newcolumntype{L}[1]{>{\raggedright\let\newline\\\arraybackslash\hspace{0pt}}m{#1}}
	\newcolumntype{C}[1]{>{\centering\let\newline\\\arraybackslash\hspace{0pt}}m{#1}}
	\newcolumntype{R}[1]{>{\raggedleft\let\newline\\\arraybackslash\hspace{0pt}}m{#1}}

	%% Improve ThreePartTable
	\newcommand\Note[1]{\item[] \parskip 0pt \begingroup \par \parshape0 \textsc{Note}.--- #1  \par \endgroup }
	\newcommand\Source[1]{\item[] \parskip 0pt \begingroup \par \parshape0 \textsc{Source}.--- #1 \par \endgroup }
	\renewcommand{\TPTminimum}{\linewidth} %% Give full width to threeparttable

	%% Used by -esttab- in the significance footnotes
	\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}

%% Common Preamble (copy-pasted)
	\usepackage{ifxetex}
	\ifxetex
	    % XeLaTeX
	    %% http://nitens.org/taraborelli/TeXOpenType
	    %% http://tex.stackexchange.com/questions/37561/getting-started-with-minion-pro-xelatex-and-mathspec
	    % Text fonts
	    \usepackage{fontspec}
	    \defaultfontfeatures{Ligatures=TeX,Scale=MatchLowercase}
	    \setmainfont[]{Minion Pro} %% Numbers=OldStyle -> bug, cannot copy-paste from PDF
	    \setsansfont[Numbers={Monospaced,Lining}]{Myriad Pro}
	    
	    % Math fonts
	    %\setmathsfont(Digits,Latin){Minion Pro}
	    %\setmathsfont(Greek){Minion Pro}
	    %\setmathrm{Minion Pro}

	    % Section and title fonts
	    \usepackage{sectsty,titling}
	    \allsectionsfont{\sffamily}
	    \newfontfamily\secfont{Myriad Pro}
	    %\renewcommand{\maketitlehooka}{\secfont}

	    % Language
	    \usepackage{polyglossia}
	    \setdefaultlanguage{english}

	    % Misc
	    \usepackage{url}
	    \usepackage[svgnames]{xcolor}
	    %%
	    %% Unsure: xunicode
		
		\usepackage[xetex]{geometry} %% Allows -newgeometry- command, to change geometry mid-document (useful with a huge table)
	\else
	    % default: pdfLaTeX
	    \usepackage[english]{babel}
	    \usepackage[T1]{fontenc}
	    \usepackage{lmodern}
	    \usepackage[adobe-utopia]{mathdesign}
	    \usepackage[utf8]{inputenc}
	    \usepackage[babel=true]{microtype}

	    \usepackage[pdflatex]{geometry} %% Allows -newgeometry- command, to change geometry mid-document (useful with a huge table)
	\fi

	% Shared
	% use upquote if available, for straight quotes in verbatim environments
	\IfFileExists{upquote.sty}{\usepackage{upquote}}{}
	% use microtype if available
	\IfFileExists{microtype.sty}{\usepackage{microtype}}{}

	\usepackage{csquotes} %% Stata doesn't handle `quotes' well, this is a workaround

%% Body (just the table)
\begin{document}
