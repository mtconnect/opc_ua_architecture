% ************************ MTCONNECT DOCUMENT CLASS *********************** %
% ************************************************************************* %
% 	FILENAME: 		mtc-opc.cls											%
%	VERSION:		0.1														%
% 	DATE:			02/13/2018												%
%	PORTED BY:		Moneer Helu												%
%	ADDRESS:		Engineering Laboratory									%
%					National Institute of Standards and Technology (NIST)	%
%					100 Bureau Drive										%
%					Mailstop 8260											%
%					Gaithersburg, MD 20899									%
%					United States of America								%
% 	EMAIL:			moneer.helu@nist.gov									%
% 	DESCRIPTION:	Style template for MTConnect documentation;				%
% 					Initial attempt for testing and discussion				%
% 	USAGE:			\documentclass[options]{mtc-opc}						%
% ************************************************************************* %

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{mtc-opc}[2018/02/13 LaTeX document class for MTConnect]

\LoadClass[12pt,letterpaper,twoside]{article}


% **************************** %
% 	Preliminary Declarations   %
% **************************** %
\usepackage[letterpaper,top=1in,%
            bottom=1in,footskip=0.5in]{geometry}

\RequirePackage{morewrites}
\RequirePackage[htt]{hyphenat}				% Allow hyphenation of fixed space fonts
\RequirePackage{fancyvrb}
\RequirePackage{placeins}
\RequirePackage{booktabs}
%\RequirePackage{tabu}
\RequirePackage{tabularx}
\RequirePackage{times}					% Loads Adobe Times Roman Font (clone of Times New Roman)
\RequirePackage{mathptmx}				% Loads Adobe Times Roman Math Font
\RequirePackage{ifpdf}					% Enables switch between latex and pdflatex
\RequirePackage{stringstrings}			% Loads stringstrings to create Camel and Pascal case fonts
\RequirePackage{ifthen}					% Loads ifthen package for conditional statements
\RequirePackage[T1]{fontenc}			% Loads fontenc package for controlled vocabulary formatting
\let\BreakableUnderscore\undefined
\RequirePackage{underscore}
\RequirePackage{graphicx}				% Loads graphicx package to include figures and images
\RequirePackage{fancyhdr}				% Loads fancyhdr package to modify headers and footers
\RequirePackage[hyphens]{url}					% Loads url package to typeset URLs
\RequirePackage{lineno}					% Loads lineno package to apply line numbers to document
\RequirePackage{etoolbox}				% Loads etoolbox package to patch lineno package and suppress line numbers in section headings
\RequirePackage{sectsty}				% Loads sectsty package to modify font of section headings
\RequirePackage[table]{xcolor}					% Loads xcolor package to define color for fonts and tables
\RequirePackage{colortbl}				% Loads colortbl package to provide colors for table shading
\RequirePackage{caption}				% Loads caption package to adjust caption font
\RequirePackage{listings}				% Loads listings package to typeset code samples
\RequirePackage{hyperref}				% Loads hyperref package to link TOC/LOF/LOT
\RequirePackage{tocloft}				% Loads tocloft package to format TOC/LOF/LOT
\RequirePackage[ampersand]{easylist}	% Loads easylist package to simplify lists using &
\RequirePackage[english]{babel}
\RequirePackage{csquotes}
\RequirePackage{xstring}
\RequirePackage{siunitx}
\RequirePackage{upgreek}
\RequirePackage{longtable}
\RequirePackage{enumitem}
\usepackage{amsmath}
\usepackage{amssymb}
\usepackage{amssymb}
\usepackage{amsmath}
\RequirePackage[acronym,toc,numberedsection,%
  abbreviations,automake,nonumberlist,%
  section=subsubsection]{glossaries-extra}
\usepackage{mdframed}
\usepackage[titletoc,title]{appendix}
\usepackage{rotating}
\usepackage{graphicx}
\usepackage[normalem]{ulem}
\renewcommand{\appendixname}{Annex}
\usepackage{titlesec}


\usepackage[citations,hybrid,smartEllipses,hashEnumerators,html,%
           pipeTables,tableCaptions,fencedCode,codeSpans,tightLists=false,%
           cacheDir=markdowncache]{markdown}
           \usepackage[absolute]{textpos}

\renewcommand{\markdownRendererHeadingOne}[1]{\section{#1}}

% *********** %
% 	Options   %
% *********** %

%\DeclareOption{draft}{\linenumbers}								% Includes line numbers
%\DeclareOption{final}{}											% Document for public release
%\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}	% Other options are passed to report class

%\ExecuteOptions{draft}		% Default option if none selected by user
%\ProcessOptions				% Executes each option selected

% ************************* %
% 	Controlled Vocabulary   %
% ************************* %

\newcommand{\mtconnect}{MTConnect\textsuperscript{\textregistered} }

\newcommand{\storedstringPCR}[1]{{\fontfamily{pcr}\selectfont #1}}

\newcommand{\cvoc}[2]{%
	\ifthenelse{\equal{#1}{tag}}{%
		\solelylowercase[e]{#2}%
	    \capitalizewords[e]{\thestring}%
		\noblanks[q]{\thestring}%
		{\fontfamily{pcr}\selectfont \thestring}}{%
	\ifthenelse{\equal{#1}{attribute}}{%
	    \solelylowercase[e]{#2}%
	    \getaword[e]{\thestring}{1}%
	    \retokenize[q]{\thestring}%
	    \storedstringPCR{\thestring}%
	    \solelylowercase[e]{#2}%
	    \removeword[e]{\thestring}%
	    \capitalizewords[e]{\thestring}%
	    \noblanks[q]{\thestring}%
	    {\fontfamily{pcr}\selectfont \storedstringPCR\thestring}}{%
	\ifthenelse{\equal{#1}{limited}}{%
	    \convertchar[e]{#2}{ }{\_}%
	    {\fontfamily{pcr}\selectfont \caseupper[v]{\thestring}}}{
	\ifthenelse{\equal{#1}{noref}}{
	    #2}{%
	\textbf{INCORRECT CONTROL VOCABULARY!!!}}}}}
}

% *************** %
% 	Page Layout   %
% *************** %



\setlength\paperheight{11in}
\setlength\paperwidth{8.5in}
\setlength\oddsidemargin{0in}
\setlength\evensidemargin{0in}

\setlength\parindent{0pt}
\setlength\parskip{1em}

% ************** %
% 	Title Page   %
% ************** %

\newcommand\@docnum{}
\newcommand\@doctitle{}
\newcommand\@doctitleshort{}
\newcommand\@doctitlepart{}
\newcommand\@doctitlesubpart{}
\newcommand\@doctitledesc{}
\newcommand\@versionnum{}
\newcommand\@preparedfor{}
\newcommand\@preparedby{}
\newcommand\@preparedon{}
\newcommand\@versiontext{}

\newcommand\getversionnum{\@versionnum}
\newcommand\getversiontext{\@versiontext}
\newcommand\getdocnum{\@docnum}
\newcommand\getdoctitle{\@doctitle}
\newcommand\getdoctitlepart{\@doctitlepart}
\newcommand\getdoctitlesubpart{\@doctitlesubpart}
\newcommand\gettitledesc{\@doctitledesc}
\newcommand\getdoctitleshort{\@doctitleshort}

\newcommand{\doctitleshort}[1]{\gdef\@doctitleshort{#1}}
\newcommand{\docnum}[1]{\gdef\@docnum{#1}}
\newcommand{\doctitle}[1]{\gdef\@doctitle{#1}}
\newcommand{\doctitlepart}[1]{\gdef\@doctitlepart{#1}}
\newcommand{\doctitlesubpart}[1]{\gdef\@doctitlesubpart{#1}}
\newcommand{\doctitledesc}[1]{\gdef\@doctitledesc{#1}}
\newcommand{\versionnum}[1]{\gdef\@versionnum{#1}}
\newcommand{\preparedfor}[1]{\gdef\@preparedfor{#1}}
\newcommand{\preparedby}[1]{\gdef\@preparedby{#1}}
\newcommand{\preparedon}[1]{\gdef\@preparedon{#1}}
\newcommand{\versiontext}[1]{\gdef\@versiontext{#1}}

\definecolor{opcblue}{rgb}{0.31,0.5,0.74}

\renewcommand{\maketitle}{%
  \begin{titlepage}%
    \TPGrid{20}{40}%
    \textblockorigin{0in}{0in}%
    \TPMargin{6pt}%
    \begin{textblock}{7}(2,3.2)%
      \includegraphics[height=0.9in]{opc-logo.jpg}%
    \end{textblock}%
    \begin{textblock}{7}(10,3.2)%
      \includegraphics[height=0.9in]{mtconnect.png}%
    \end{textblock}%
    %
    \TPMargin{0in}%
    \textblockcolor{light-gray}%
    \begin{textblock}{19}(0,9.5)%
      \hrule%
      \color{opcblue}    %
      \hspace{1in} \huge{\bf{\@docnum}}%
      \vspace{12pt}%
    \end{textblock}%
    %
    \TPMargin{1in}%
    %
    \textblockcolor{white}%
    \begin{textblock}{14}(2,12)%
      \color{black}%
      \LARGE{\bf{\@doctitleshort}}%
      \newline%
      \LARGE{\bf{\@doctitlepart}}%
      \vspace{1in}%
      \LARGE{\bf{\@doctitledesc}}%
      \newline%
      \LARGE{\bf{\getversiontext\ \getversionnum}}%
      \newline%
      \LARGE{\bf{\@preparedon}}%
      \vspace{1in}%
    \end{textblock}%
    %
    \textblockcolor{light-gray}%
    \TPMargin{12pt}%
    \begin{textblock}{1.5}(18.5,0)%
      \vspace{3in}%
      \rotatebox[origin=lB]{270}{\LARGE{\bf{OPC UA Companion Specification \@doctitlesubpart}}}%
      \vspace{4in}%
    \end{textblock}%
    %
    \newpage%
    \textbf{}%
    %
    \color{black}%
    \TPoptions{absolute=false}%
  \end{titlepage}%
  \setcounter{page}{1}%
}

% ************************************ %
% 	Table of Contents/Figures/Tables   %
% ************************************ %

\renewcommand\contentsname{Table of Contents}
\renewcommand\listfigurename{List of Figures}
\renewcommand\listtablename{List of Tables}

\renewcommand{\cftsubsecindent}{1.25em}
\renewcommand{\cftsubsubsecindent}{2.5em}

\renewcommand{\cftfigfont}{\normalsize\bfseries}
\renewcommand{\cftfigindent}{0pt}
\renewcommand{\cftfignumwidth}{4.8em}
\renewcommand{\cftfigpresnum}{Figure }
\renewcommand{\cftfigaftersnum}{:}

\renewcommand{\cfttabfont}{\normalsize\bfseries}
\renewcommand{\cfttabindent}{0pt}
\renewcommand{\cfttabnumwidth}{5em}
\renewcommand{\cfttabpresnum}{Table }
\renewcommand{\cfttabaftersnum}{:}

% ********************************* %
% 	Header and Footer Definitions   %
% ********************************* %

\pagestyle{fancy}
\fancyhf{}
\rhead{\@preparedon}
\lfoot{\@doctitle \newline \@doctitlepart \space \@doctitlesubpart { --} \@versiontext\space\@versionnum}
\rfoot{\thepage}
\renewcommand{\headrulewidth}{0pt}

% ************************** %
% 	Sections and Enumerate   %
% ************************** %

\setcounter{secnumdepth}{5}
\setcounter{tocdepth}{3}

\makeatletter
\renewcommand\subparagraph{%
	\@startsection {subparagraph}{5}{\z@ }{3.25ex \@plus 1ex
	\@minus .2ex}{-1em}{\normalfont \normalsize \bfseries }}%
\makeatother

\sectionfont{\bfseries\color{black}\fontsize{18}{20}\selectfont}
\subsectionfont{\bfseries\color{black}\fontsize{16}{18}\selectfont}
\subsubsectionfont{\bfseries\color{black}\fontsize{14}{16}\selectfont}
\paragraphfont{\bfseries\color{black}\fontsize{13}{14}\selectfont}
\subparagraphfont{\bfseries\color{black}\normalsize\selectfont}

\newcommand{\onesection}[1]{\section{#1}}
\newcommand{\twosection}[1]{\subsection{#1}}
\newcommand{\threesection}[1]{\subsubsection{#1}}
\newcommand{\foursection}[1]{\paragraph{#1}\mbox{}\\}
\newcommand{\fivesection}[1]{\subparagraph{#1}\mbox{}\\}

\newcommand{\hang}{\hangindent=0.5in}

% ********************** %
% 	Tables and Figures   %
% ********************** %

\definecolor{mtc2}{RGB}{0,128,128}
\newcommand{\tblh}[1]{\normalsize\textbf{\textcolor{white}{#1}}}

\graphicspath{ {./figures/} }

\newcommand{\figcap}[1]{\caption{\textbf{#1}}}
\captionsetup{labelfont=bf}

% **************** %
% 	Line Numbers   %
% **************** %

\renewcommand\linenumberfont{\footnotesize\fontfamily{pcr}\selectfont}
\makeatletter
\patchcmd{\@startsection}{\@ifstar}{\nolinenumbers\@ifstar}{}{}
\patchcmd{\@xsect}{\ignorespaces}{\linenumbers\ignorespaces}{}{}
\makeatother
\linenumbers

% ************************* %
% 	Controlled Vocabulary   %
% ************************* %

\newcommand{\deprecated}[1]{{\fontfamily{pcr}\selectfont #1}}
\newcommand{\deprecationwarning}[1]{{\fontfamily{pcr}\selectfont #1}}

\newcommand{\mtterm}[1]{\textit{#1}}
\newcommand{\uaterm}[1]{\textit{\textbf{{#1}}}}
\newcommand{\xml}[1]{{\fontfamily{pcr}\selectfont #1}}
\newcommand{\mtmodel}[1]{{\fontfamily{pcr}\selectfont #1}}
\newcommand{\uamodel}[1]{\textbf{\fontfamily{pcr}\selectfont #1}}
\newcommand{\var}[1]{\textit{\fontfamily{pcr}\selectfont @#1}}


% ****************** %
% 	Other Commands   %
% ****************** %

% Courier font selection:
\newcommand{\cfont}[1]{{\fontfamily{pcr}\selectfont #1}}

% Requirement levels:
\newcommand{\must}{\textbf{MUST }}
\newcommand{\mustnot}{\textbf{MUST NOT }}
\newcommand{\should}{\textbf{SHOULD }}
\newcommand{\shouldnot}{\textbf{SHOULD NOT }}
\newcommand{\may}{\textbf{MAY }}
\newcommand{\maynot}{\textbf{MAY NOT }}
\newcommand{\shall}{\textbf{SHALL }}
\newcommand{\shallnot}{\textbf{SHALL NOT }}

% Formatting for cross-references:
\newcommand{\fig}[1]{\textit{Figure~\ref{#1} }}
\newcommand{\sect}[1]{\textit{Section~\ref{#1} }}
\newcommand{\doc}[1]{\textit{#1 }}
\newcommand{\ver}[1]{\textit{MTConnect Version #1 }}

% Formatting for code samples:
\newcommand{\code}{%
\lstset{basicstyle=\footnotesize\fontfamily{pcr}\selectfont,numbers=left,stepnumber=1,xleftmargin=0.25in}}

\lstset{basicstyle=\small, xrightmargin=0.25in, 
  frame=single, framexrightmargin=0.5in, breaklines,
  breakautoindent=true}

\definecolor{maroon}{rgb}{0.5,0,0}
\definecolor{darkgreen}{rgb}{0,0.5,0}

% Formatting for internal links in document:
\hypersetup{%
	colorlinks=true,
    linkcolor=black,
    filecolor=magenta,
    urlcolor=blue,
    citecolor=maroon
}

% Use styles for OPC and UML drawings
\usepackage{sty/tikz-opc}
\usepackage{sty/tikz-uml}
\usetikzlibrary{positioning}
\usetikzlibrary{arrows,calc,decorations.markings,math,arrows.meta}

\tikzumlset{fill class=white, fill template=white}

\tikzstyle{tikzuml unidirectional association style}=%
   [color=\tikzumlDefaultDrawColor, {-{Stealth[inset=3pt,scale=2.5,angle'=45]}},%
   rounded corners]

\tikzstyle{tikzuml inherit style}=%
   [color=\tikzumlDefaultDrawColor, {-{Stealth[inset=0pt,scale=2.5,fill=white,angle'=45]}},%
   rounded corners]

\lstdefinelanguage{XML}
{
  basicstyle=\ttfamily\footnotesize,
  morestring=[b]",
  moredelim=[s][\bfseries\color{maroon}]{<}{\ },
  moredelim=[s][\bfseries\color{maroon}]{</}{>},
  moredelim=[l][\bfseries\color{maroon}]{/>},
  moredelim=[l][\bfseries\color{maroon}]{>},
  morecomment=[s]{<?}{?>},
  morecomment=[s]{<!--}{-->},
  commentstyle=\color{darkgreen},
  stringstyle=\color{blue},
  identifierstyle=\color{red}
}

\newcommand{\atsign}{\char`\@}

\newcommand{\typeref}[1]{\hyperref[type:#1]{#1}}

\newcommand*{\mtuatype}[1]{\hyperref[type:#1]{\fontfamily{pcr}\selectfont #1}}

\newcommand*{\mtuaenum}[1]{\hyperref[enum:#1]{\fontfamily{pcr}\selectfont #1}}

\newcommand*{\mtuadatatype}[1]{\hyperref[data-type:#1]{\fontfamily{pcr}\selectfont #1}}

\newcommand*{\mtuamodel}[1]{\hyperref[model:#1]{\fontfamily{pcr}\selectfont #1}}

% Glossary info

\setglossarystyle{altlist}
\newglossary*{opc}{OPC UA Terms}
\newglossary*{mtc}{MTConnect Terms}
\makeglossaries

% For acronyms, puts the long description first and then the acronym second.
\setabbreviationstyle[acronym]{long-short}
\glscategory{code}

% Sets the font based on the type of glossary entry being referenced
\defglsentryfmt[opc]{%
  \glsifcategory{\glslabel}{code}%
    {\uamodel{\glsgenentryfmt}}%
    {\uaterm{\glsgenentryfmt}}}
  
\defglsentryfmt[mtc]{%
  \glsifcategory{\glslabel}{code}%
    {\mtmodel{\glsgenentryfmt}}%
    {\mtterm{\glsgenentryfmt}}}

\renewcommand{\glsnamefont}[1]{%
  \ifglsfieldeq{\glscurrententrylabel}{type}{opc}{%
    \glsifcategory{\glscurrententrylabel}{code}%
      {\uamodel{#1}}%
      {\uaterm{#1}}%
  }{%
    \ifglsfieldeq{\glscurrententrylabel}{type}{mtc}{%
      \glsifcategory{\glscurrententrylabel}{code}%
        {\mtmodel{#1}}%
        {\mtterm{#1}}%
    }%
    {\textbf{#1}}%
  }%
}

\newcommand{\mantis}[1]{\href{https://apps.opcfoundation.org/mantis/view.php?id=#1}{#1}}
