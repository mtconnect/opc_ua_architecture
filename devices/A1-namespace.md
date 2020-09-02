
# MTConnect Namespace and  Mappings \newline (normative)

## Namespace and identifiers for MTConnect Information Model

This appendix defines the numeric identifiers for all of the numeric NodeIds defined in this specification. The identifiers are specified in a CSV file with the following syntax:

```<SymbolName>, <Identifier>, <NodeClass>```

Where the {{uablock(SymbolName)}} is either the {{term(BrowseName)}} of a Type {{term(Node)}} or the {{uablock(BrowsePath)}} for an {{uablock(Instance)}} {{uablock(Node)}} that appears in the specification and the Identifier is the numeric value for the {{term(NodeId)}}.

The {{uablock(BrowsePath)}} for an Instance {{term(Node)}} is constructed by appending the {{term(BrowseName)}} of the instance {{term(Node)}} to the {{term(BrowseName)}} for the containing instance or type. An underscore character is used to separate each {{term(BrowseName)}} in the path. Let’s take for example, the {{mtmodel(MTComponentType)}} {{uamodel(ObjectType)}} Node which has the {{mtmodel(NativeName)}} {{term(Property)}}. The {{uamodel(Name)}} for the {{mtmodel(NativeName)}} {{uablock(InstanceDeclaration)}} within the {{mtmodel(MTComponentType)}} declaration is as follows: {{mtmodel(MTComponentType_NativeName)}}.

The CSV associated with this version of the standard can be found here:%
>  http://www.opcfoundation.org/UA/schemas/MTConnect/2.0/MTConnect.NodeIds.csv

NOTE The latest CSV that is compatible with this version of the standard can be found here:%
> http://www.opcfoundation.org/UA/schemas/MTConnect/MTConnect.NodeIds.csv

A computer processible version of the complete {{uablock(Information Model)}} defined in this specification is also provided. It follows the {{term(xml)}} {{uablock(Information Model)}} schema syntax defined in OPC {{cite(UAPart6)}}.

The information schema for this version of the standard, including all errata, can be found at the following URL:%
> http://www.opcfoundation.org/UA/schemas/MTConnect/2.0/Opc.Ua.MTConnect.NodeSet2.xml

NOTE:  The latest information schema for this version of the standard, including all errata, can be found at the following URL:%
> http://www.opcfoundation.org/UA/schemas/MTConnect/Opc.Ua.MTConnect.NodeSet2.xml

