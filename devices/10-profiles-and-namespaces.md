# Profiles and Namespaces  {#profiles-and-namespaces}

## Namespace Metadata

Table {{table(namespacemetadata)}} defines the {{uablock(namespace)}} {{uablock(metadata)}} for this specification. The {{term(Object)}} is used to provide information for the {{uablock(namespace)}} and an indication about static {{termplural(Node)}}. Static {{termplural(Node)}} are identical for all {{termplural(Attribute)}} in all {{termplural(Server)}}, including the {{uablock(Value)}} {{term(Attribute)}}. See {{cite(UAPart5)}} for more details.

The information is provided as {{term(Object)}} of type {{uamodel(NamespaceMetadataType)}}. This {{term(Object)}} is a component of the {{uablock(Namespaces)}} {{term(Object)}} that is part of the {{term(Server)}} {{term(Object)}}. The {{uamodel(NamespaceMetadataType)}} {{uamodel(ObjectType)}} and its {{termplural(Property)}} are defined in {{cite(UAPart5)}}.

The version information is also provided as part of the {{uamodel(ModelTableEntry)}} in the {{term(UANodeSet)}} XML file. The {{term(UANodeSet)}} {{term(xml)}} schema is defined in {{cite(UAPart6)}}.

| Attribute | Value |
|----------------|------------|
| BrowseName | http://www.opcfoundation.org/UA/MTConnect/2.0/ |
{: caption="`NamespaceMetadata`" format-1="p 1.88in" format-2="p 3.92in" label="namespacemetadata" }

| References | BrowseName | DataType | Value |
|------------|------------|----------|-------|
| HasProperty | NamespaceUri | String | http://www.opcfoundation.org/UA/MTConnect/2.0/ |
| HasProperty | NamespaceVersion | String | 2.0 |
| HasProperty | NamespacePublicationDate | DateTime | 2018-10-31T00:00:00 |
| HasProperty | IsNamespaceSubset | Boolean |  False |
| HasProperty | StaticNodeIdTypes | IdType\[\] |  \[0\] |
| HasProperty | StaticNumericNodeIdRange | NumericRange\[\] | \[1:1073741824\] |
| HasProperty | StaticStringNodeIdPattern | String | |
{: format="p 0.85in" }

## Conformance Units and Profiles

This chapter defines the corresponding {{uablock(Profiles)}} and {{uablock(Conformance Units)}} for the OPC UA Information Model for MTConnect. {{uablock(Profiles)}} are named groupings of {{uablock(Conformance Units)}}. {{uablock(Facets)}} are {{uablock(Profiles)}} that will be combined with other {{uablock(Profiles)}} to define the complete functionality of an OPC UA {{term(Server)}} or {{uablock(Client)}}.

### Server

Table {{table(server-conformance)}} defines the {{term(Server)}} based {{uablock(ConformanceUnits)}}.

| Conformance Unit | Description | Optional/ Mandatory   |
|------------------|-------------|:---------------------:|
| MTConnect Base Functionality | The server supports the {{uablock(BaseObjectModel)}}. This includes exposing all mandatory objects, variables, methods, and data types. | M |
| Availability | The Server must support the {{mtmodel(Availability)}} {{term(MTDataItem)}} to indicate if data is available from the device. | M |
| Device | The Server has at least one root {{mtuatype(MTDeviceType)}} | M |
| AssetChanged Data Item | The Server must support the MTConnect AssetChanged and AssetRemoved data items  | O |
| Message | The Server must support the MTConnect Message data item and publish {{mtuatype(MTMessageEventType)}} {{uamodel(Event)}}s | M |
| Condition | The server must support the MTConnect {{mtuatype(MTConditionType)}} type and provide correct activation states  | M |
| Condition Branches | The server must support MTConnect {{mtuatype(MTConditionType)}} condition branches to represent multiple MTConnect Condition parallel activations | O |
| Three Space Sample | The server must support the {{mtuatype(MTThreeSpaceSampleType)}} data type to provide a spacial coordinate | M |
| MTHasClassType and MTHasSubClassType | The server must have {{mtuatype(MTSampleType)}}, {{mtuatype(MTStringEventType)}} {{mtuatype(MTMessageType)}}, {{mtuatype(MTNumericEventType)}}, and {{mtuatype(MTControlledVariableType)}} with relationships to the MTConnect Class types associated with the MTConnect {{mtmodel(DataItem)}} {{mtmodel(type)}} and {{mtmodel(subType)}} | M |
| MTConnect meta data | DataItems represented in OPC UA must have the full meta data required by the MTConnect standard for all attributes | M |
| Engineer Units | All {{mtuatype(MTSampleType)}} data items must have the {{uamodel(EngineeringUnits)}} follow the prescribed Units as specified in the MTConnect standard.  | M |
| 
| {{latex(\rowfont)}}{{latex(\bfseries)}} Conformance Unit | Description | Optional/ Mandatory |
| MTConnect Base Functionality | The server supports the {{uablock(BaseObjectModel)}}. This includes exposing all mandatory objects, variables, methods, and data types. | M |
| Availability | The Server must support the {{mtmodel(Availability)}} {{term(MTDataItem)}} to indicate if data is available from the device. | M |
| Device | The Server has at least one root {{mtuatype(MTDeviceType)}} | M |
| AssetChanged Data Item | The Server must support the MTConnect AssetChanged and AssetRemoved data items  | O |
| Message | The Server must support the MTConnect Message data item and publish {{mtuatype(MTMessageEventType)}} {{uamodel(Event)}}s | M |
| Condition | The server must support the MTConnect {{mtuatype(MTConditionType)}} type and provide correct activation states  | M |
| Condition Branches | The server must support MTConnect {{mtuatype(MTConditionType)}} condition branches to represent multiple MTConnect Condition parallel activations | O |
| Three Space Sample | The server must support the {{mtuatype(MTThreeSpaceSampleType)}} data type to provide a spacial coordinate | M |
| MTHasClassType and MTHasSubClassType | The server must have {{mtuatype(MTSampleType)}}, {{mtuatype(MTStringEventType)}} {{mtuatype(MTMessageType)}}, {{mtuatype(MTNumericEventType)}}, and {{mtuatype(MTControlledVariableType)}} with relationships to the MTConnect Class types associated with the MTConnect {{mtmodel(DataItem)}} {{mtmodel(type)}} and {{mtmodel(subType)}} | M |
| MTConnect meta data | DataItems represented in OPC UA must have the full meta data required by the MTConnect standard for all attributes | M |
| Engineer Units | All {{mtuatype(MTSampleType)}} data items must have the {{uamodel(EngineeringUnits)}} follow the prescribed Units as specified in the MTConnect standard.  | M |
{: format-2="p"   caption="MTConnect *Server* Model" label="server-conformance" }

### Client

Table {{table(client-conformance)}} defines the {{uablock(Client)}} based {{uablock(ConformanceUnits)}}.

| Conformance Unit | Description | Optional/ Mandatory |
|------------------|-------------|:---------------------:|
| MTConnect Base Functionality | The client supports the {{uablock(BaseObjectModel)}}. This includes exposing all mandatory objects, variables, methods, and data types. | M |
| Availability | The client must interpret the {{mtmodel(Availability)}} {{term(MTDataItem)}} to indicate if data is available from the device. | M |
{: format-2="p"   caption="MTConnect *Client* Model" label="client-conformance" }

{{FloatBarrier}}

## Handling of OPC UA Namespaces

{{uablock(Namespaces)}} are used by OPC UA to create unique identifiers across different naming authorities. The Attributes {{term(NodeId)}} and {{term(BrowseName)}} are identifiers. A {{term(Node)}} in the UA {{term(AddressSpace)}} is unambiguously identified using a NodeId. Unlike {{termplural(NodeId)}}, the {{term(BrowseName)}} cannot be used to unambiguously identify a {{term(Node)}}. Different {{termplural(Node)}} may have the same {{term(BrowseName)}}. They are used to build a browse path between two Nodes or to define a standard {{term(Property)}}.

{{termplural(Server)}} may often choose to use the same namespace for the {{term(NodeId)}} and the {{term(BrowseName)}}. However, if they want to provide a standard {{term(Property)}}, its gls{BrowseName} shall have the {{uablock(namespace)}} of the standards body although the {{uablock(namespace)}} of the {{term(NodeId)}} reflects something else, for example the {{uamodel(EngineeringUnits)}} {{term(Property)}}. All {{termplural(NodeId)}} of {{termplural(Node)}} not defined in this specification shall not use the standard {{uablock(namespaces)}}.

Table {{table(server-namespaces)}} provides a list of mandatory and optional namespaces used in an MTConnect OPC UA {{term(Server)}}.

| NamespaceURI | Description | Use |
|--------------|-------------|-----|
| http://www.opcfoundation.org/UA/ | {{uablock(Namespace)}} for {{termplural(NodeId)}} and {{termplural(BrowseName)}} defined in the OPC UA specification. This {{uablock(namespace)}} shall have {{uablock(namespace)}} index 0. | Mandatory |
| Local Server URI | {{uablock(Namespace)}} for nodes defined in the local server. This may include types and instances used in an {{uablock(AutoID)}} Device represented by the {{term(Server)}}. This {{uablock(namespace)}} shall have {{uablock(namespace)}} index 1. | Mandatory |
| http://www.opcfoundation.org/UA/MTConnect/2.0/ | {{uablock(Namespace)}} for {{termplural(NodeId)}} and {{termplural(BrowseName)}} defined in this specification. The {{uablock(namespace)}} index is {{term(Server)}} specific. | Mandatory |
| Vendor specific types & A {{term(Server)}} may provide vendor-specific types like types derived from {{uablock(ObjectTypes)}} defined in this specification in a vendor-specific {{uablock(namespace)}}. | Optional |
| Vendor specific instances & A {{term(Server)}} provides vendor-specific instances of the standard types or vendor-specific instances of vendor-specific types in a vendor-specific {{uablock(namespace)}}. It is recommended to separate vendor specific types and vendor specific instances into two or more {{uablock(namespaces)}}. | Mandatory |
{: caption="Namespaces used in a MTConnect Server"  label="server-namespaces" }


Table~{{table(namespaces)}} provides a list of {{uablock(namespaces)}} and their index used for {{termplural(BrowseName)}} in this specification. The default {{uablock(namespace)}} of this specification is not listed since all {{termplural(BrowseName)}} without prefix use this default {{uablock(namespace)}}.

| NamespaceURI | Namespace Index | Example |
|--------------|----------------:|---------|
| http://www.opcfoundation.org/UA/ | 0 | 0:EngineeringUnits |
| http://www.opcfoundation.org/UA/MTConnect/2.0/ | 1 | 1:MTDevice |
{: caption="Namespaces used used in this specification" label="namespaces" }

