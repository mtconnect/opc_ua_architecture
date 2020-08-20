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

Conventions {#conventions}
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

{{latex(\printglossary[type=opc])}}

{{latex(\printglossary[type=mtc])}}

{{latex(\printacronyms)}}

### Conventions for Node descriptions


{{term(Node)}} definitions are specified using tables (see Table {{table(TypeDefinitionTable)}}).

{{termplural(Attribute)}} are defined by providing the Attribute name and a value, or a description of the value.

{{termplural(Reference)}} are defined by providing the {{term(ReferenceType)}} name, the {{term(BrowseName)}} of the {{term(TargetNode)}} and its {{term(NodeClass)}}.

- If the {{term(TargetNode)}} is a component of the {{term(Node)}} being defined in the table the {{termplural(Attribute)}} of the composed Node are defined in the same row of the table.
51
- The {{term(DataType)}} is only specified for Variables; "\[\<number\>\]"
  indicates a single-dimensional array, for multi-dimensional arrays
  the expression is repeated for each dimension (e.g. `[2][3]` for
  a two-dimensional array). For all arrays the
  {{termplural(ArrayDimension)}} is set as identified by
  {{uablock(\<number\>)}} values. If no {{uablock(\<number\>)}} is set,
  the corresponding dimension is set to 0, indicating an unknown
  size. If no number is provided at all the
  {{termplural(ArrayDimension)}} can be omitted. If no brackets are
  provided, it identifies a scalar {{term(DataType)}} and the
  {{term(ValueRank)}} is set to the corresponding value (see
  {{cite(UAPart3)}}). In addition, {{termplural(ArrayDimension)}} is
  set to {{uablock(null)}} or is omitted. If it can be
  {{uablock(Any)}} or {{uablock(ScalarOrOneDimension)}}, the value is
  put into {{uablock("\<value\>")}}, so either {{uablock("Any")}} or
  {{uablock("ScalarOrOneDimension")}} and the {{term(ValueRank)}} is
  set to the corresponding value (see {{cite(UAPart3)}}) and the
  {{termplural(ArrayDimension)}} is set to {{uablock(null)}} or is
  omitted. Examples are given in Table {{table(ExamplesOfDataTypes)}}.

- The {{term(TypeDefinition)}} is specified for {{termplural(Object)}} and {{termplural(Variable)}}.
- The {{term(TypeDefinition)}} column specifies a symbolic name for a {{term(NodeId)}}, i.e. the specified {{term(Node)}} points with a {{term(HasTypeDefinition)}} {{term(Reference)}} to the corresponding {{term(Node)}}.
- The {{term(ModellingRule)}} of the referenced component is provided by specifying the symbolic name of the rule in {{term(ModellingRule)}}. In the {{term(AddressSpace)}}, the {{term(Node)}} shall use a {{term(HasModellingRule)}} {{term(Reference)}} to point to the corresponding {{term(ModellingRule)}} {{term(Object)}}.

{{latex(\FloatBarrier)}}

| Notation | DataType | ValueRank | ArrayDimensions | Description(2.75in) | 
|----------|----------|-----------:|-----------------|-------------|
| Int32 | Int32 | -1 | omitted or null | A scalar Int32. |
| Int32\[\]	| Int32 | 1 | omitted or {0} | Single-dimensional array of Int32 with an unknown size. |
| Int32\[\]\[\] | Int32 | 2 | omitted or {0,0} | Two-dimensional array of Int32 with unknown sizes for both dimensions. |
| Int32\[3\]\[\] | Int32 | 2 | {3,0} | Two-dimensional array of Int32 with a size of 3 for the first dimension and an unknown size for the second dimension. |
| Int32\[5\]\[3\] | Int32 | 2 |
{:  caption="Examples of DataTypes" format-1="p 0.75in" format-5="p 2.75in" }


{{latex(\FloatBarrier)}}

If the {{term(NodeId)}} of a {{term(DataType)}} is provided, the symbolic name of the {{term(Node)}} representing the {{term(DataType)}} shall be used.

Nodes of all other {{termplural(NodeClass)}} cannot be defined in the same table; therefore only the used {{term(ReferenceType)}}, their {{term(NodeClass)}} and their {{term(BrowseName)}} are specified. A reference to another part of this document points to their definition.

Table {{table(TypeDefinitionTable)}} illustrates the table. If no components are provided, the {{term(DataType)}}, {{term(TypeDefinition)}} and {{term(ModellingRule)}} columns may be omitted and only a Comment column is introduced to point to the {{term(Node)}} definition.

| Attribute | Value |
|----------------|------------|
|Attribute name  |Attribute value. If it is an optional Attribute that is not set "--" will be used.|
{: caption="Type Definition Table" format-1="p 1.88in" format-2="p 3.59in"}


| References     | NodeClass      | BrowseName      | DataType      | TypeDefinition      | Modeling Rule      |
|----------------|----------------|-----------------|---------------|---------------------|--------------------|
| ReferenceType name | NodeClass of the target Node. | BrowseName of the target Node. If the Reference is to be instantiated by the server, then the value of the target Node's BrowseName is "--". | DataType of the referenced Node, only applicable for Variable. | TypeDefinition of the referenced Node, only applicable for Variable and Object. | Referenced ModellingRule of the referenced Object.|
| {{span(6)}} Note: Notes referencing footnotes of the table content.  |
{: format="p 0.85in" }


{{latex(\FloatBarrier)}}

Components of {{termplural(Node)}} can be complex that is containing components by themselves. The {{term(TypeDefinition)}}, {{term(NodeClass)}}, {{term(DataType)}} and {{term(ModellingRule)}} can be derived from the type definitions, and the symbolic name can be created. Therefore, those containing components are not explicitly specified; they are implicitly specified by the type definitions.

## NodeIds and BrowseNames

### NodeIds

The {{termplural(NodeId)}} of all {{termplural(Node)}} described in this standard are only symbolic names. Annex A defines the actual {{termplural(NodeId)}}.

The symbolic name of each {{term(Node)}} defined in this specification is its {{term(BrowseName)}}, or, when it is part of another Node, the {{term(BrowseName)}} of the other {{term(Node)}}, a ".", and the {{term(BrowseName)}} of itself. In this case "part of" means that the whole has a {{term(HasProperty)}} or {{term(HasComponent)}} Reference to its part. Since all {{termplural(Node)}} not being part of another {{term(Node)}} have a unique name in this specification, the symbolic name is unique.

The namespace for all {{termplural(NodeId)}} defined in this specification is defined in Annex A. The namespace for this {{uablock(NamespaceIndex)}} is Server-specific and depends on the position of the namespace URI in the server namespace table.

Note that this specification not only defines concrete {{termplural(Node)}}, but also requires that some Nodes shall be generated, for example one for each Session running on the Server. The {{termplural(NodeId)}} of those {{termplural(Node)}} are Server-specific, including the namespace. But the {{uablock(NamespaceIndex)}} of those {{termplural(Node)}} cannot be the {{uablock(NamespaceIndex)}} used for the Nodes defined in this specification, because they are not defined by this specification but generated by the Server.

#### BrowseNames

The text part of the {{uablock(BrowseNames)}} for all {{term(Node)}}s defined in this specification is specified in the tables defining the Nodes. The {{uablock(NamespaceIndex)}} for all {{uablock(BrowseNames)}} defined in this specification is defined in Annex A.

### Common Attributes

#### General

The {{termplural(Attribute)}} of {{termplural(Node)}}, their {{uablock(DataTypes)}} and descriptions are defined in {{termplural(UAPart3)}}. {{termplural(Attribute)}} not marked as optional are mandatory and shall be provided by a Server. The following tables define if the {{term(Attribute)}} value is defined by this specification or if it is server-specific.

For all Nodes specified in this specification, the {{termplural(Attribute)}} named in Table {{table(CommonNodeAttributes)}} shall be set as specified in the table.

| Attribute | Value |
|----------------|------------|
|DisplayName | The DisplayName is a LocalizedText. Each server shall provide the DisplayName identical to the BrowseName of the Node for the LocaleId "en". Whether the server provides translated names for other LocaleIds is server-specific.|
|Description | Optionally a server-specific description is provided.|
|NodeClass | Shall reflect the NodeClass of the Node.|
|NodeId | The NodeId is described by BrowseNames.|
|WriteMask | Optionally the WriteMask Attribute can be provided. If the WriteMask Attribute is provided, it shall set all non-server-specific Attributes to not writable. For example, the Description Attribute may be set to writable since a Server may provide a server-specific description for the Node. The NodeId shall not be writable, because it is defined for each Node in this specification.|
|UserWriteMask | Optionally the UserWriteMask Attribute can be provided. The same rules as for the WriteMask Attribute apply.|
|RolePermissions | Optionally server-specific role permissions can be provided.|
|UserRolePermissions | Optionally the role permissions of the current Session can be provided. The value is server-specifc and depend on the RolePermissions Attribute (if provided) and the current Session.|
|AccessRestrictions | Optionally server-specific access restrictions can be provided. |
{: caption="Common Node Attributes" format-1="p 1.5in" format-2="p 3.9in"}

#### Objects

For all `Objects` specified in this specification, the `Attributes` named in Table {{table(CommonObjectAttributes)}} shall be set as specified in the Table {{table(CommonObjectAttributes)}}. The definitions for the `Attributes` can be found in OPC {{termplural(UAPart3)}}.

|Attribute|Value|
|----------------|------------|
| EventNotifier | Whether the Node can be used to subscribe to Events or not is server-specific. |
{: caption="Common Object Attributes" format-1="p 1.5in" format-2="p 3.9in"}

{{latex(\FloatBarrier)}}

#### Variables

For all {{termplural(Variable)}} specified in this specification, the {{termplural(Attribute)}} named in Table {{table(CommonVariableAttributes)}} shall be set as specified in the table. The definitions for the {{termplural(Attribute)}} can be found in {{termplural(UAPart3)}}.

|Attribute|Value|
|----------------|------------|
| EventNotifier | Whether the Node can be used to subscribe to Events or not is server-specific. |
| MinimumSamplingInterval | Optionally, a server-specific minimum sampling interval is provided.|
| AccessLevel | The access level for Variables used for type definitions is server-specific, for all other Variables defined in this specification, the access level shall allow reading; other settings are server-specific.|
| UserAccessLevel | The value for the UserAccessLevel Attribute is server-specific. It is assumed that all Variables can be accessed by at least one user.|
| Value | For Variables used as InstanceDeclarations, the value is server-specific; otherwise it shall represent the value described in the text.|
| ArrayDimensions | If the ValueRank does not identify an array of a specific dimension (i.e. ValueRank <= 0) the ArrayDimensions can either be set to null or the Attribute is missing. This behaviour is server-specific. If the ValueRank specifies an array of a specific dimension (i.e. ValueRank > 0) then the ArrayDimensions Attribute shall be specified in the table defining the Variable.|
| Historizing | The value for the Historizing Attribute is server-specific.|
| AccessLevelEx | If the AccessLevelEx Attribute is provided, it shall have the bits 8, 9, and 10 set to 0, meaning that read and write operations on an individual Variable are atomic, and arrays can be partly written. |
{: caption="Common Variable Attributes" format-0="p 1.5in" format-1="p 3.9in"}


{{latex(\FloatBarrier)}}

#### VariableTypes

For all {{latex(\uamodel{VariableType}}} specified in this specification, the {{termplural(Attribute)}} named in Table {{table(CommonVariableTypesAttributes)}} shall be set as specified in the table. The definitions for the {{termplural(Attribute)}} can be found in {{termplural(UAPart3)}}.

|Attribute|Value|
|----------------|------------|
| Value | Optionally a server-specific default value can be provided. |
| ArrayDimensions | If the ValueRank does not identify an array of a specific dimension (i.e. ValueRank <= 0) the ArrayDimensions can either be set to null or the Attribute is missing. This behaviour is server-specific. If the ValueRank specifies an array of a specific dimension (i.e. ValueRank > 0) then the ArrayDimensions Attribute shall be specified in the table defining the VariableType. |
{: caption="Common VariableTypes Attributes" format-0="p 1.5in" format-1="p 3.9in"}

{{latex(\FloatBarrier)}}

#### Methods

For all {{latex(\uamodel{Methods}}} specified in this specification, the {{term(Attribute)}} named in Table {{table(CommonMethodAttributes)}} shall be set as specified in the table. The definitions for the {{termplural(Attribute)}} can be found in {{termplural(UAPart3)}}.

|Attribute|Value|
|----------------|------------|
| Executable | All Methods defined in this specification shall be executable (Executable Attribute set to “True”), unless it is defined differently in the Method definition.|
| UserExecutable | The value of the UserExecutable Attribute is server-specific. It is assumed that all Methods can be executed by at least one user. |
{: caption="Common Method Attributes" format-0="p 1.5in" format-1="p 3.9in"}


{{latex(\FloatBarrier)}}
