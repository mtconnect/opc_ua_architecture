Terms, Definitions and Conventions {#termsdefinitionsconventions}
==================================

Overview
--------

The basic concepts of OPC UA and MTConnect are pre-requisites for
understanding and interpreting the content provided in this companion
specification. Additionally, the terms and definitions given in
{{cite(UAPart1)}}, {{cite(UAPart2)}}, {{cite(UAPart3)}}, {{cite(UAPart5)}}, {{cite(UAPart7)}}, {{cite(UAPart10)}},
and {{cite(MTCPart1)}}, (see section {{ref(normativereferences)}}, as well as the following, apply to
this document.

Conventions
-----------

Following are basic conventions that shall be followed for all formal
definitions used: MTConnect Terms will be displayed as follows using
italic font (). OPC UA Terms will use bold italic fonts (). Terms will
be linked to the associated glossary entry if available.

MTConnect {{term(xml)}}
literals and code will appear in monospace and OPC UA literals and UA
Model will appear as bold monospace .

Terms and Acronnyms
-------------------

\printglossary[type=opc]

\printglossary[type=mtc]

\printacronyms

### Conventions for Node descriptions


{{term(Node)}} definitions are specified using tables (see Table {{ref(table:TypeDefinitionTable)}}).

{{termplural(Attribute)}} are defined by providing the Attribute name and a value, or a description of the value.

{{termplural(Reference)}} are defined by providing the {{term(ReferenceType)}} name, the {{term(BrowseName)}} of the {{term(TargetNode)}} and its {{term(NodeClass)}}.

- If the {{term(TargetNode)}} is a component of the {{term(Node)}} being defined in the table the {{termplural(Attribute)}} of the composed Node are defined in the same row of the table.
- The {{term(DataType)}} is only specified for Variables; "[<number>]" indicates a single-dimensional array, for multi-dimensional arrays the expression is repeated for each dimension (e.g. `[2][3]` for a two-dimensional array). For all arrays the {{termplural(ArrayDimension)}} is set as identified by {{uablock(<number>)}} values. If no {{uablock(<number>)}} is set, the corresponding dimension is set to 0, indicating an unknown size. If no number is provided at all the {{termplural(ArrayDimension)}} can be omitted. If no brackets are provided, it identifies a scalar {{term(DataType)}} and the {{term(ValueRank)}} is set to the corresponding value (see {{cite(UAPart3)}}). In addition, {{termplural(ArrayDimension)}} is set to {{uablock(null)}} or is omitted. If it can be {{uablock(Any)}} or {{uablock(ScalarOrOneDimension)}}, the value is put into {{uablock("<value>")}}, so either {{uablock("Any")}} or {{uablock("ScalarOrOneDimension")}} and the {{term(ValueRank)}} is set to the corresponding value (see {{cite(UAPart3)}}) and the {{termplural(ArrayDimension)}} is set to {{uablock(null)}} or is omitted. Examples are given in Table {{ref(table:ExamplesOfDataTypes)}}.
- The {{term(TypeDefinition)}} is specified for {{termplural(Object)}} and {{termplural(Variable)}}.
- The {{term(TypeDefinition)}} column specifies a symbolic name for a {{term(NodeId)}}, i.e. the specified {{term(Node)}} points with a {{term(HasTypeDefinition)}} {{term(Reference)}} to the corresponding {{term(Node)}}.
- The {{term(ModellingRule)}} of the referenced component is provided by specifying the symbolic name of the rule in {{term(ModellingRule)}}. In the {{term(AddressSpace)}}, the {{term(Node)}} shall use a {{term(HasModellingRule)}} {{term(Reference)}} to point to the corresponding {{term(ModellingRule)}} {{term(Object)}}.

: Examples of DataTypes

| Notation | DataType | ValueRank | ArrayDimensions | Description |
|----------|----------|-----------|-----------------|-------------|
| Int32 | Int32 | -1 | omitted or null | A scalar Int32.
| Int32[]	| Int32 | 1 | omitted or \{0\} | Single-dimensional array of Int32 with an unknown size. |
| Int32[][] | Int32 | 2 | omitted or \{0,0\} | Two-dimensional array of Int32 with unknown sizes for both dimensions. |
| Int32[3][] | Int32 | 2 | \{3,0\} | Two-dimensional array of Int32 with a size of 3 for the first dimension and an unknown size for the second dimension. |
| Int32[5][3] | Int32 | 2 | \{5,3\} | Two-dimensional array of Int32 with a size of 5 for the first dimension and a size of 3 for the second dimension. |
| Int32\{Any\} | Int32 | -2 | omitted or null | An Int32 where it is unknown if it is scalar or array with any number of dimensions. |
| Int32 \{ScalarOrOneDimension\} | Int32 | -3 | omitted or null | An Int32 where it is either a single-dimensional array or a scalar.


\FloatBarrier


