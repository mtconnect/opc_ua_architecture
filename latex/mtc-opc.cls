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
\usepackage{geometry}
    \geometry{letterpaper}
    
\RequirePackage{fancyvrb}
\RequirePackage{placeins}
\RequirePackage{booktabs}
\RequirePackage{tabu}
\RequirePackage{times}					% Loads Adobe Times Roman Font (clone of Times New Roman)
\RequirePackage{mathptmx}				% Loads Adobe Times Roman Math Font
\RequirePackage{ifpdf}					% Enables switch between latex and pdflatex
\RequirePackage{stringstrings}			% Loads stringstrings to create Camel and Pascal case fonts
\RequirePackage{ifthen}					% Loads ifthen package for conditional statements
\RequirePackage[T1]{fontenc}			% Loads fontenc package for controlled vocabulary formatting
\RequirePackage{underscore}				% Loads underscore package for underscores in text
\RequirePackage{graphicx}				% Loads graphicx package to include figures and images
\RequirePackage{fancyhdr}				% Loads fancyhdr package to modify headers and footers
\RequirePackage[hyphens]{url}					% Loads url package to typeset URLs
\RequirePackage{lineno}					% Loads lineno package to apply line numbers to document
\RequirePackage{etoolbox}				% Loads etoolbox package to patch lineno package and suppress line numbers in section headings
\RequirePackage{sectsty}				% Loads sectsty package to modify font of section headings
\RequirePackage{xcolor}					% Loads xcolor package to define color for fonts and tables
\RequirePackage{colortbl}				% Loads colortbl package to provide colors for table shading
\RequirePackage{caption}				% Loads caption package to adjust caption font
\RequirePackage{listings}				% Loads listings package to typeset code samples
\RequirePackage{hyperref}				% Loads hyperref package to link TOC/LOF/LOT
\RequirePackage{tocloft}				% Loads tocloft package to format TOC/LOF/LOT
\RequirePackage[ampersand]{easylist}	% Loads easylist package to simplify lists using &
\RequirePackage[english]{babel}
\RequirePackage{csquotes}

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
\setlength\oddsidemargin{0.25in}
\setlength\evensidemargin{0.25in}

\setlength\parindent{0pt}
\setlength\parskip{1em}

% ************** %
% 	Title Page   %
% ************** %

\newcommand\@docnum{}
\newcommand\@doctitle{}
\newcommand\@versionnum{}
\newcommand\@preparedfor{}
\newcommand\@preparedby{}
\newcommand\@preparedon{}
\newcommand\@drafttext{}
\newcommand{\docnum}[1]{\gdef\@docnum{#1}}
\newcommand{\doctitle}[1]{\gdef\@doctitle{#1}}
\newcommand{\versionnum}[1]{\gdef\@versionnum{#1}}
\newcommand{\preparedfor}[1]{\gdef\@preparedfor{#1}}
\newcommand{\preparedby}[1]{\gdef\@preparedby{#1}}
\newcommand{\preparedon}[1]{\gdef\@preparedon{#1}}
\newcommand{\drafttext}[1]{\gdef\@drafttext{#1}}

\renewcommand{\maketitle}{%
	\begin{titlepage}%
    	\begin{center}%
        	\includegraphics[width=0.4\linewidth]{mtconnect.png} 
        	\includegraphics[width=0.4\linewidth]{opc-logo.jpg} \\%
        \end{center}%
        \vfill%
        \begin{center}%
            \huge{\@doctitle} \protect\\%
            \LARGE{\quad \protect\\\@drafttext \@versionnum \protect\\ \quad \protect\\\@preparedon} \protect\\%
        \end{center}%
        \vfill%
        %\hspace*{\fill}%
		%\begin{tabular}[t]{l@{}}%
		%	Prepared for: \@preparedfor \\%
		%	Prepared by: \@preparedby \\%
        %	Prepared on: \@preparedon \\%
		%\end{tabular}%
		%\vfill%
		\noindent \footnotesize{\mtconnect is a registered trademark of AMT - The Association for Manufacturing Technology. Use of \mtconnect is limited to use as specified on \url{http://www.mtconnect.org/}.}%
    \end{titlepage}%
    \setcounter{page}{1}%
}

% ************************************ %
% 	Table of Contents/Figures/Tables   %
% ************************************ %

\renewcommand\contentsname{\color{mtc1} Table of Contents}
\renewcommand\listfigurename{\color{mtc1} List of Figures}
\renewcommand\listtablename{\color{mtc1} List of Tables}

\renewcommand{\cftfigfont}{\normalsize\bfseries}
\renewcommand{\cftfigindent}{0pt}
\renewcommand{\cftfignumwidth}{4.25em}
\renewcommand{\cftfigpresnum}{Figure }
\renewcommand{\cftfigaftersnum}{:}

% ********************************* %
% 	Header and Footer Definitions   %
% ********************************* %

\newcommand\@doctitleshort{}
\newcommand{\doctitleshort}[1]{\gdef\@doctitleshort{#1}}

\pagestyle{fancy}
\fancyhf{}
\rhead{\@preparedon}
\lfoot{\@drafttext \@doctitleshort { -} Version \@versionnum}
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

% \definecolor{mtc1}{RGB}{43,105,145}
\definecolor{mtc1}{RGB}{0,0,0}
\sectionfont{\bfseries\color{mtc1}\fontsize{20}{22}\selectfont}
\subsectionfont{\bfseries\color{mtc1}\fontsize{18}{20}\selectfont}
\subsubsectionfont{\bfseries\color{black}\fontsize{16}{18}\selectfont}
\paragraphfont{\bfseries\color{black}\fontsize{14}{16}\selectfont}
\subparagraphfont{\bfseries\color{black}\normalsize}

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

% Formatting for internal links in document:
\hypersetup{%
	colorlinks=true,
    linkcolor=black,
    filecolor=magenta,
    urlcolor=blue
}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Library for OPC UA Nodes and References%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\usepackage{tikz}
\usetikzlibrary{shadows.blur}
\usetikzlibrary{shapes,arrows, arrows.meta}
\usetikzlibrary{decorations.markings}
\usepackage{xifthen}
\usepackage[outline]{contour}
\usepackage{caption}
\usetikzlibrary{decorations.pathreplacing}
\usetikzlibrary{shapes.multipart}

%References
%   \Reference{NAME}{SOURCE}{PATH_PROFILE}{DESTINATION}{OPTIONAL_ARGUMENTS};
%   \HasComponent{}{Reservation}{--}{Cancel}{};

%Nodes
%   \Node{NAME}{RELATIVE_POSITION}{RELATIVE_TO}{NODE_DISTANCE};
%   \Method{Cancel}{right of}{Reservation}{3.5};

\newcommand{\defaultstyle}{
\tikzset{every picture/.style={/utils/exec={\sffamily}}};
\contourlength{1.2pt}
}

%References

%Sym/Asym references

%Symmetric Reference
\newcommand{\SymmetricReference}[5]{
\defaultstyle;
\tikzstyle{triangle} = [draw, very thick, color=black!70, -{Triangle[scale=1.5]}];
\path [triangle] (#4) #3 (#2);
\path [triangle] (#2) #3 (#4) node [midway, above, text width = 2cm, align= center, #5] (TextNode) {\contour{white}{#1}};
}

%Asymmetric Reference
\newcommand{\AsymmetricReference}[5]{
\defaultstyle;
\tikzstyle{triangle} = [draw, very thick, color=black!70, -{Triangle[scale=1.5]}];
\path [triangle] (#2) #3 (#4) node [midway, above, text width = 2cm, align= center, #5] (TextNode) {\contour{white}{#1}};
}

%HasEventSource references

\newcommand{\HasEventSource}[5]{
\defaultstyle;
\tikzstyle{triangle2} = [draw, very thick, color=black!70, -{Triangle[scale=1.5, open]}];
\path [triangle2] (#2) #3 (#4) node [midway, above, text width = 2cm, align= center, #5] (TextNode) {\contour{white}{#1}};
}

%HasTypeDefinition references

\newcommand{\HasTypeDefinition}[5]{
\defaultstyle;
\tikzstyle{triangle3} = [draw, very thick, color=black!70, -{Triangle[scale=1.5]}, postaction ={draw, shorten >=0.8em, -{Triangle[scale=1.5]}}];
\path [triangle3] (#2) #3 (#4) node [midway, above, text width = 2cm, align= center, #5] (TextNode) {\contour{white}{#1}};
}

%HasSubType references

\newcommand{\HasSubType}[5]{
\defaultstyle;
\tikzstyle{triangle4} = [draw, very thick, color=black!70, -{Triangle[scale=1.5, open]}, postaction ={draw, shorten >=0.8em, -{Triangle[scale=1.5, open, fill = white!=100]}}];
\path [triangle4] (#4) #3 (#2) node [midway, above, text width = 2cm, align= center, #5] (TextNode) {\contour{white}{#1}};
}

%Hierarchical references

\newcommand{\HierarchicalReference}[5]{
\defaultstyle;
\tikzstyle{angle} = [draw, very thick, color=black!70, -{Straight Barb[angle'=60,scale=2]}];
\path [angle] (#2) #3 (#4) node [midway, above, text width = 2cm, align= center, #5] (TextNode) {\contour{white}{#1}};
}

%HasComponent references

\newcommand{\HasComponent}[5]{
\defaultstyle;
\tikzstyle{barb} = [draw, very thick, color=black!70, -, postaction ={draw, shorten >=0.7em, -{|[scale=1]}} ];
\path [barb] (#2) #3 (#4) node [midway, above, text width = 2cm, align= center, #5] (TextNode) {\contour{white}{#1}};
}

%HasProperty references

\newcommand{\HasProperty}[5]{
\defaultstyle;
\tikzstyle{barb2} = [draw, very thick, color=black!70, -, postaction ={draw, shorten >=0.7em, -{|[scale=1]}, postaction ={draw, shorten >=1em, -{|[scale=1]}}}];
\path [barb2] (#2) #3 (#4) node [midway, above, text width = 2cm, align= center, #5] (TextNode) {\contour{white}{#1}};
}


%Node Classes

%TYPES
\newcommand{\defaultstyletypes}{
\tikzset{
    render blur shadow/.prefix code={
      \colorlet{black}{cyan!15}}
}
}

%ObjectType

\newcommand{\ObjectType}[5]{
\defaultstyletypes;
\tikzstyle{typeobjecttype} = [rectangle, draw, fill=cyan!7, blur shadow ={shadow xshift=2ex, shadow yshift=-2ex, shadow scale=\number1} , minimum width=6em, text centered, minimum height=3em];
    %node distance default 
    \ifthenelse{\equal{#4}{}}{\def \nd {2}}{\def \nd {#4}}
    
    %position default
    \ifthenelse{\equal{#2}{} \AND \equal{#3}{}}{\def \posL {node distance}, \def \posR {\nd cm}}{\def \posL {#2}, \def \posR {#3}}
    
    \node [typeobjecttype, \posL = \posR, node distance = \nd cm, #5] (#1) {\emph{#1}}
}

%VariableType

\newcommand{\VariableType}[5]{
\defaultstyletypes;
\tikzstyle{typevariabletype} = [rectangle, draw, fill=cyan!7, blur shadow ={shadow xshift=2ex, shadow yshift=-2ex, shadow scale=1}, minimum width=6em, text centered, rounded corners = 5pt, minimum height=3em];
    %node distance default 
    \ifthenelse{\equal{#4}{}}{\def \nd {2}}{\def \nd {#4}}
    
    %position default
    \ifthenelse{\equal{#2}{} \AND \equal{#3}{}}{\def \posL {node distance}, \def \posR {\nd cm}}{\def \posL {#2}, \def \posR {#3}}
    \node [typevariabletype, \posL = \posR, node distance = \nd cm, #5] (#1) {\emph{#1}}
}

%DataType

\newcommand{\DataType}[5]{
\defaultstyletypes;
\tikzstyle{typedatatype} = [chamfered rectangle, chamfered rectangle angle = 20, chamfered rectangle xsep=1cm, chamfered rectangle ysep = 0.3cm, draw, fill= cyan!7, blur shadow ={shadow xshift=2ex, shadow yshift=-2ex, shadow scale=1}, minimum width=6em, text centered , minimum height = 3em];
    %node distance default 
    \ifthenelse{\equal{#4}{}}{\def \nd {2}}{\def \nd {#4}}
    
    %position default
    \ifthenelse{\equal{#2}{} \AND \equal{#3}{}}{\def \posL {node distance}, \def \posR {\nd cm}}{\def \posL {#2}, \def \posR {#3}}
    
    \node [typedatatype, \posL = \posR, node distance = \nd cm, #5] (#1) {\emph{#1}}
}

%ReferenceType
\newcommand{\ReferenceType}[5]{
    \defaultstyletypes;
    
    %Can be an option argument scale: default as 3.
    \def \customscale {3}; %{#X}
    %\ifthenelse{\customscale<3}{\def \customscale {3}}{}
    
    %node distance default 
    \ifthenelse{\equal{#4}{}}{\def \nd {2}}{\def \nd {#4}};
    
    %position default
    \ifthenelse{\equal{#2}{} \AND \equal{#3}{}}{\def \posL {node distance}, \def \posR {\nd cm}}{\def \posL {#2}, \def \posR {#3}};
    
    \coordinate [\posL = \posR, node distance = \nd cm] (center);
    
    \path (center) -- + (-0.4*\customscale,0.2*\customscale) coordinate (A);
    \draw (A) -- + (1.2*\customscale,0) coordinate (B);
    \draw (B) -- + (-0.1*\customscale,-0.2*\customscale) coordinate (C);
    \draw (C) -- + (+0.1*\customscale,-0.2*\customscale) coordinate (D);
    \draw (D) -- + (-1.2*\customscale,0) coordinate (E);
    \draw (E) -- + (-0.1*\customscale,0.2*\customscale) coordinate (F);
    \draw (F) -- + (0.1*\customscale,0.2*\customscale) coordinate (G);
    \filldraw[draw,  fill = cyan!7, blur shadow ={ shadow xshift=2ex, shadow yshift=-2ex, shadow scale=1}] (A) -- (B) -- (C) -- (D) -- (E) -- (F) -- (G);
    \node [minimum width = 3cm, text width = 2.5cm, align = center, minimum height= 1.15 cm, #5] (#1) at (center) {\emph{#1}}
}


%INSTANCES
%Object

\newcommand{\Object}[5]{
\tikzstyle{instanceobject} = [rectangle, draw, fill=black!7, drop shadow , minimum width=6em, text centered, minimum height=3em];
    %node distance default 
    \ifthenelse{\equal{#4}{}}{\def \nd {2}}{\def \nd {#4}}
    
    %position default
    \ifthenelse{\equal{#2}{} \AND \equal{#3}{}}{\def \posL {node distance}, \def \posR {\nd cm}}{\def \posL {#2}, \def \posR {#3}}
    
    \node [instanceobject, \posL = \posR, node distance = \nd cm, #5] (#1) {#1};
}


%Variable

\newcommand{\Variable}[5]{
\tikzstyle{instancevariable} = [rectangle, draw, fill=black!7,drop shadow , minimum width=6em, text centered, rounded corners = 5pt, minimum height=3em];
    %node distance default 
    \ifthenelse{\equal{#4}{}}{\def \nd {2}}{\def \nd {#4}}
    
    %position default
    \ifthenelse{\equal{#2}{} \AND \equal{#3}{}}{\def \posL {node distance}, \def \posR {\nd cm}}{\def \posL {#2}, \def \posR {#3}}
    
    \node [instancevariable,\posL = \posR, node distance = \nd cm, #5] (#1) {#1};
}


%Method

\newcommand{\Method}[5]{
\tikzstyle{instancemethod} = [ellipse, draw, fill=black!7,drop shadow ,  minimum width=6em, text centered, minimum height=3em];
    %node distance default 
    \ifthenelse{\equal{#4}{}}{\def \nd {2}}{\def \nd {#4}}
    
    %position default
    \ifthenelse{\equal{#2}{} \AND \equal{#3}{}}{\def \posL {node distance}, \def \posR {\nd cm}}{\def \posL {#2}, \def \posR {#3}}
    \node [instancemethod,\posL = \posR, node distance = \nd cm, #5] (#1) {#1}
}

%View

\newcommand{\View}[5]{
\tikzstyle{instanceview} = [trapezium, trapezium left angle = 80, trapezium right angle = 80,  draw, fill=black!7,drop shadow ,minimum width=6em, text centered, minimum height =3 em];
    
    %node distance default 
    \ifthenelse{\equal{#4}{}}{\def \nd {2}}{\def \nd {#4}}
    
    %position default
    \ifthenelse{\equal{#2}{} \AND \equal{#3}{}}{\def \posL {node distance}, \def \posR {\nd cm}}{\def \posL {#2}, \def \posR {#3}}
    
    \node [instanceview, \posL = \posR, node distance = \nd cm, #5] (#1) {#1}
}

%Empty node

\newcommand{\Coordinate}[5]{
    %node distance default 
    \ifthenelse{\equal{#4}{}}{\def \nd {2}}{\def \nd {#4}}
    
    %position default
    \ifthenelse{\equal{#2}{} \AND \equal{#3}{}}{\def \posL {node distance}, \def \posR {\nd cm}}{\def \posL {#2}, \def \posR {#3}}
    
    \coordinate [ \posL = \posR, node distance = \nd cm, #5] (#1) {}
}