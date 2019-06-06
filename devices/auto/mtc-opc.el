(TeX-add-style-hook
 "mtc-opc"
 (lambda ()
   (TeX-add-to-alist 'LaTeX-provided-class-options
                     '(("article" "12pt" "letterpaper" "twoside")))
   (TeX-add-to-alist 'LaTeX-provided-package-options
                     '(("geometry" "letterpaper" "top=1in" "bottom=1in" "footskip=0.5in") ("hyphenat" "htt") ("fontenc" "T1") ("url" "hyphens") ("easylist" "ampersand") ("babel" "english") ("glossaries-extra" "acronym" "toc" "numberedsection" "abbreviations" "automake" "nonumberlist" "section=subsubsection") ("appendix" "titletoc" "title")))
   (add-to-list 'LaTeX-verbatim-environments-local "lstlisting")
   (add-to-list 'LaTeX-verbatim-environments-local "VerbatimOut")
   (add-to-list 'LaTeX-verbatim-environments-local "SaveVerbatim")
   (add-to-list 'LaTeX-verbatim-environments-local "LVerbatim*")
   (add-to-list 'LaTeX-verbatim-environments-local "LVerbatim")
   (add-to-list 'LaTeX-verbatim-environments-local "BVerbatim*")
   (add-to-list 'LaTeX-verbatim-environments-local "BVerbatim")
   (add-to-list 'LaTeX-verbatim-environments-local "Verbatim*")
   (add-to-list 'LaTeX-verbatim-environments-local "Verbatim")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperref")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperimage")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperbaseurl")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "nolinkurl")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "lstinline")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "url")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "path")
   (add-to-list 'LaTeX-verbatim-macros-with-delims-local "lstinline")
   (add-to-list 'LaTeX-verbatim-macros-with-delims-local "path")
   (add-to-list 'LaTeX-verbatim-macros-with-delims-local "Verb")
   (TeX-run-style-hooks
    "latex2e"
    "article"
    "art12"
    "geometry"
    "morewrites"
    "hyphenat"
    "fancyvrb"
    "placeins"
    "booktabs"
    "tabu"
    "times"
    "mathptmx"
    "ifpdf"
    "stringstrings"
    "ifthen"
    "fontenc"
    "underscore"
    "graphicx"
    "fancyhdr"
    "url"
    "lineno"
    "etoolbox"
    "sectsty"
    "xcolor"
    "colortbl"
    "caption"
    "listings"
    "hyperref"
    "tocloft"
    "easylist"
    "babel"
    "csquotes"
    "xstring"
    "siunitx"
    "upgreek"
    "longtable"
    "enumitem"
    "amsmath"
    "amssymb"
    "glossaries-extra"
    "mdframed"
    "appendix"
    "rotating"
    "titlesec"
    "sty/tikz-opc"
    "sty/tikz-uml")
   (TeX-add-symbols
    '("mantis" 1)
    '("mtuamodel" 1)
    '("mtuadatatype" 1)
    '("mtuaenum" 1)
    '("mtuatype" 1)
    '("typeref" 1)
    '("ver" 1)
    '("doc" 1)
    '("sect" 1)
    '("fig" 1)
    '("cfont" 1)
    '("var" 1)
    '("uamodel" 1)
    '("mtmodel" 1)
    '("xml" 1)
    '("uaterm" 1)
    '("mtterm" 1)
    '("deprecationwarning" 1)
    '("deprecated" 1)
    '("figcap" 1)
    '("tblh" 1)
    '("fivesection" 1)
    '("foursection" 1)
    '("threesection" 1)
    '("twosection" 1)
    '("onesection" 1)
    '("versiontext" 1)
    '("preparedon" 1)
    '("preparedby" 1)
    '("preparedfor" 1)
    '("versionnum" 1)
    '("doctitlepart" 1)
    '("doctitle" 1)
    '("docnum" 1)
    '("doctitleshort" 1)
    '("cvoc" 2)
    '("storedstringPCR" 1)
    "mtconnect"
    "getversionnum"
    "getversiontext"
    "getdocnum"
    "getdoctitle"
    "getdoctitlepart"
    "getdoctitleshort"
    "maketitlecontent"
    "hang"
    "must"
    "mustnot"
    "should"
    "shouldnot"
    "may"
    "maynot"
    "shall"
    "shallnot"
    "code"
    "atsign"
    "BreakableUnderscore")
   (LaTeX-add-saveboxes
    "titlecontent")
   (LaTeX-add-xcolor-definecolors
    "mtc2"
    "maroon"
    "darkgreen"))
 :latex)

