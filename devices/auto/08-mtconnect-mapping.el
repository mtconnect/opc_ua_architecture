(TeX-add-style-hook
 "08-mtconnect-mapping"
 (lambda ()
   (add-to-list 'LaTeX-verbatim-environments-local "Verbatim")
   (add-to-list 'LaTeX-verbatim-environments-local "Verbatim*")
   (add-to-list 'LaTeX-verbatim-environments-local "BVerbatim")
   (add-to-list 'LaTeX-verbatim-environments-local "BVerbatim*")
   (add-to-list 'LaTeX-verbatim-environments-local "LVerbatim")
   (add-to-list 'LaTeX-verbatim-environments-local "LVerbatim*")
   (add-to-list 'LaTeX-verbatim-environments-local "SaveVerbatim")
   (add-to-list 'LaTeX-verbatim-environments-local "VerbatimOut")
   (add-to-list 'LaTeX-verbatim-environments-local "lstlisting")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "lstinline")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "nolinkurl")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperbaseurl")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperimage")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperref")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "path")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "url")
   (add-to-list 'LaTeX-verbatim-macros-with-delims-local "url")
   (add-to-list 'LaTeX-verbatim-macros-with-delims-local "Verb")
   (add-to-list 'LaTeX-verbatim-macros-with-delims-local "lstinline")
   (add-to-list 'LaTeX-verbatim-macros-with-delims-local "path")
   (TeX-run-style-hooks
    "diagrams/mtconnect-mapping/mtcomponent-ua"
    "diagrams/mtconnect-mapping/mtcomponent-uml"
    "diagrams/mtconnect-mapping/example-object"
    "diagrams/mtconnect-mapping/device-model"
    "diagrams/mtconnect-mapping/mtdevice-data-item"
    "diagrams/mtconnect-mapping/data-item-references"
    "diagrams/mtconnect-mapping/linear-x-component")
   (TeX-add-symbols
    "rownumber")
   (LaTeX-add-labels
    "mtconnect-mapping"
    "sec:mapping-rules"
    "table:execution-data-type"
    "sec:browse-name-rules"
    "item:component-browse-name"
    "item:composition-browse-name"
    "sec:data-item-conventions"
    "item:browse-name"
    "item:representation"
    "item:statistic"
    "item:data-item-name"
    "item:condition-browse-name"
    "table:enineering-untis-data-type"
    "table:mtconnect-to-ua-eu-mapping"
    "line:linear-position"
    "line:rotary-mode"
    "line:programmed-rotary-velocity"
    "line:actual-rotary-velocity"
    "line:rotary-c-load"
    "line:rotary-c-amperage"
    "line:rotary-c-amperage-condition"
    "line:rotary-c-motor"
    "fig:rotary-c-rotary-mode"
    "fig:rotary-c-rotary-velocity"
    "fig:rotary-c-load"
    "fig:rotary-c-amperage"
    "fig:controller-component"
    "fig:path-component"
    "line:electric-temp-60"
    "line:electric-voltage-10"
    "line:electric-voltage-ampere"
    "line:electric-amperage"
    "line:electric-average-amperage"
    "line:amperage-condition"
    "line:temperature-condition"
    "line:electric-temp-sensor"
    "fig:electric-system"
    "fig:electric-system-2"
    "fig:coolant-system"
    "line:component-stream-1"
    "line:pos-unavilable"
    "line:pos-795"
    "line:pos-809"
    "sec:sting-numeric-events"
    "line:prog-430"
    "line:pc-603"
    "line:cmode-255"
    "table:example-ControllerModeDataType"
    "line:amp-201"
    "line:amp-503"
    "line:amp-652"
    "fig:condition-branching"
    "table:ua-condition-states"
    "line:va-wo-sample-rate"
    "line:va-w-sample-rate"
    "eqn:ts-delta"
    "eqn:ts-first"
    "eqn:ts-second"
    "eqn:ts-n")
   (LaTeX-add-counters
    "condrownumbers"))
 :latex)

