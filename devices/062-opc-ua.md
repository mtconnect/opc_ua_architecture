## Introduction to OPC Unified Architecture {#intro-to-opc-ua}

OPC UA is an open and royalty free set of standards designed as a universal communications protocol.
While there are numerous communication solutions available, OPC UA has key advantages:

* A state of art security model (see {{cite(UAPart2)}}).
* A fault tolerant communication protocol.
* An information modeling framework that allows application developers to represent their data in a way that makes sense to them.

OPC UA has a broad scope which delivers for economies of scale for application developers. This means that a larger number of high quality applications at a reasonable cost are available. When combined with powerful semantic models such as MTConnect, OPC UA makes it easier for end users to access data via generic commercial applications.

The OPC UA model is scalable from small devices to {{term(erp)}} systems. OPC UA devices process information locally and then provide that data in a consistent format to any application requesting data - {{term(erp)}}, {{term(mes)}}, {{term(pms)}}, Maintenance Systems, {{term(hmi)}}, Smartphone or a standard Browser, for examples. For a more complete overview see {{cite(UAPart1)}}.

### Basics of OPC UA

As an Open Standard, OPC UA is based on standard Internet technologies - {{term(tcpip)}}, {{term(http)}} and Web Sockets.

As an Extensible Standard, OPC UA provides a set of services (see {{cite(UAPart4)}}) and a basic information model framework. This framework provides an easy manner for creating and exposing vendor defined information in a standard way. More importantly all OPC UA Clients are expected to be able to discover and use vendor defined information. This means OPC UA users can benefit from the economies of scale that come with generic visualization and historian applications. This specification is an example of an OPC UA Information Model designed to meet the needs of developers and users.

OPC UA Clients can be any consumer of data from another device on the network to browser base thin clients and  {{term(erp)}} systems. The full scope of OPC UA applications are shown in Figure {{figure(scopeofopcuaent)}}.

![](diagrams/ScopeOfOpcUaEnt.tex)

OPC UA provides a robust and reliable communication infrastructure having mechanisms for handling lost messages, failover, heartbeat, etc. With its binary encoded data, it offers a high-performing data exchange solution. Security is built into OPC UA as security requirements become more and more important especially since environments are connected to the office network or the internet and attackers are starting to focus on automation systems.

### Information Modeling in OPC UA

#### Concepts

OPC UA provides a framework that can be used to represent complex information as `Objects` in an `AddressSpace` which can be accessed with standard services. These Objects consist of {{termplural(Node)}} connected by `References`. Different classes of Nodes convey different semantics. For example, a {{term(Variable)}} Node represents a value that can be read or written. The `Variable` Node has an associated {{term(DataType)}} that can define the actual value, such as a string, float, structure etc. It can also describe the `Variable` value as a variant. A Method Node represents a function that can be called. Every Node has a number of `Attributes` including a unique identifier called a `NodeId` and non-localized name called as {{term(BrowseName)}}. An `Object` representing a `Reservation` is shown in Figure {{figure(opcuabasicobject)}}.


![](diagrams/OpcUaBasicObject.tex)

{{latex(\FloatBarrier)}}

`Object` and `Variable Nodes` are called `Instance Nodes` and they always reference a Type Definition (`ObjectType` or `VariableType`) Node which describes their semantics and structure. Figure {{figure(relsbetweeentypesandinstances)}} illustrates the relationship between an Instance and its Type Definition.

The Type Nodes are templates that define all of the children that can be present in an Instance of the Type. In the example in Figure {{figure(relsbetweeentypesandinstances)}} the `PersonType` `ObjectType` defines two children: First Name and Last Name. All instances of `PersonType` are expected to have the same children with the same {{termplural(BrowseName)}}. Within a Type the {{termplural(BrowseName)}} uniquely identify the child. This means Client applications can be designed to search for children based on the {{termplural(BrowseName)}} from the Type instead of `NodeIds`. This eliminates the need for manual reconfiguration of systems if a Client uses Types that multiple devices implement.

OPC UA also supports the concept of sub typing. This allows a modeler to take an existing Type and extend it. There are rules regarding sub typing defined in {{cite(UAPart3)}}, but in general they allow the additions to a given type or the restriction of a {{term(DataType)}} to a more specific data type. For example the modeler may decide that the existing `ObjectType` in some cases needs an additional variable. The modeler can create a subtype of the `ObjectType` and add the variable. A client that is expecting the parent type can treat the new `ObjectType` as if it was of the parent `ObjectType` and just ignore the additional variable. A client that understands the new subtype may display or otherwise process the additional variable. With regard to {{termplural(DataType)}}, if a variable is defined to have a numeric value, a sub type could restrict the Value to a float.

![](diagrams/RelsBetweenTypesAndInstances.tex)

References allow Nodes to be connected together in ways that describe their relationships. All References have a  `ReferenceType` that specifies the semantics of the relationship. References can be hierarchical or non-hierarchical. Hierarchical references are used to create the structure of Objects and Variables. Non-hierarchical are used to create arbitrary associations. Applications can define their own  `ReferenceType` by creating  `Subtypes` of the existing `ReferenceType`.  `Subtypes` inherit the semantics of the parent but may add additional restrictions. Figure {{figure(opcuareferencetypesfromotherreferencetypes)}} and Figure {{figure(refsbetweenobjects)}} depict several references connecting different Objects.

![](diagrams/RefsBetweenObjects.tex)

The figures above use a notation that was developed for the OPC UA specification. The notation is summarized in Figure {{figure(opcinfomodelnodeclassnotation)}} and Figure {{figure(opcinfomodelreferencesnotation)}} . UML representations can also be used; however, the OPC UA notation is less ambiguous because there is a direct mapping from the elements in the figures to {{term(Node)}} in the `AddressSpace` of an OPC UA Server.

![](diagrams/OpcInfoModelNodeClassNotation.tex)
![](diagrams/OpcInfoModelReferencesNotation.tex)

A complete description of the different types of {{termplural(Node)}} and `References` can be found in {{cite(UAPart3)}} and the base structure is described in {{cite(UAPart5)}}.
OPC UA specification defines a very wide range of functionality in its basic information model. It is not expected that all clients or servers support all functionality in the OPC UA specifications. OPC UA includes the concept of profiles, which segment the functionality into testable certifiable units. This allows the development of companion specification (such as MTConnect-OPC UA) that can describe the subset of functionality that is expected to be implemented. The profiles do not restrict functionality, but generate requirements for a minimum set of functionality (see {{cite(UAPart7)}})


#### Namespaces

OPC UA allows information from many different sources to be combined into a single coherent address space. `Namespaces` are used to make this possible by eliminating naming and id conflicts between information from different sources. `Namespaces` in OPC UA have a globally unique string called a `NamespaceUri` and a locally unique integer called a `NamespaceIndex`. The `NamespaceIndex` is only unique within the context of a Session between an OPC UA Client and an OPC UA Server. All of the web services defined for OPC UA use the `NamespaceIndex` to specify the `Namespace` for qualified values.

There are two types of values in OPC UA that are qualified with Namespaces: `NodeIds` and `QualifiedNames`. `NodeIds` are globally unique identifiers for Nodes. This means the same Node with the same `NodeId` can appear in many Servers. This, in turn, means Clients can have built in knowledge of some Nodes. OPC UA Information Models generally define globally unique `NodeIds` for the `TypeDefinitions` defined by the Information Model.

`QualifiedNames` are non-localized names qualified with a `Namespace`. They are used for the `BrowseNames` of Nodes and allow the same Names to be used by different information models without conflict. The `BrowseName` is used to identify the children within a `TypeDefinitions`. Instances of a `TypeDefinition` are expected to have children with the same `BrowseNames`. `TypeDefinitions` are not allowed to have children with duplicate `BrowseNames`; however, Instances do not have that restriction.

#### Companion Specifications

An OPC UA companion specification for an industry specific vertical market describes an Information Model by defining `ObjectTypes`, `VariableTypes`, `DataTypes` and `ReferenceTypes` (see section {{ref(conventions)}}) that represent the concepts used in the vertical market, and potentially also well-defined Objects as entry points into the `AddressSpace`.


