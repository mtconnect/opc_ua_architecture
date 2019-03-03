require 'nodeset_type'
require 'model'

class NodesetModel < Model
  def self.generate_nodeset(model)
    @@models[model].generate_nodeset
  end

  def self.nodeset_document
    document = REXML::Document.new
    document << REXML::XMLDecl.new("1.0", "UTF-8")
    
    root = document.add_element('UANodeSet')
    root.add_namespace('xsd', "http://www.w3.org/2001/XMLSchema")
    root.add_namespace('xsi', "http://www.w3.org/2001/XMLSchema-instance")
    root.add_namespace("http://opcfoundation.org/UA/2011/03/UANodeSet.xsd")

    root.add_attribute("xsi:schemaLocation",
                   "http://opcfoundation.org/UA/2011/03/UANodeSet.xsd UANodeSet.xsd")
                                                                                                                          
    root.add_attribute('LastModified', Time.now.utc.xmlschema)
    root.add_element('NamespaceUris').
      add_element('Uri').
      add_text(NamespaceUri)

    root.add_element('Models').
      add_element('Model',  { 'ModelUri' => NamespaceUri,
                              "Version" => "2.00",
                              "PublicationDate" => Time.now.utc.xmlschema }).
      add_element('RequiredModel', { "ModelUri" => "http://opcfoundation.org/UA/",
                                     "Version" => "1.04",
                                     "PublicationDate" => Time.now.utc.xmlschema } )

    # Add aliases
    als = root.add_element('Aliases')
    Ids.each_alias do |a|
      als.add_element('Alias', { 'Alias' => a }).add_text(Ids.raw_id(a))
    end

    return document
  end

  def self.type_dict_document
    document = REXML::Document.new
    document << REXML::XMLDecl.new("1.0", "UTF-8")

    root = document.add_element('opc:TypeDictionary', {'DefaultByteOrder' => "LittleEndian",
                                                           'TargetNamespace' => NamespaceUri })
    root.add_namespace('opc', "http://opcfoundation.org/BinarySchema/")
    root.add_namespace('xsi', "http://www.w3.org/2001/XMLSchema-instance")
    root.add_namespace('ua', "http://opcfoundation.org/UA/")
    root.add_namespace('tns', "http://opcfoundation.org/UA/")

    root.add_element('opc:Import', {
                       'Namespace' => "http://opcfoundation.org/UA/",
                       'Location' => "Opc.Ua.BinarySchema.bsd" })

    return document
  end

  def self.xml_type_dict_document
    document = REXML::Document.new
    document << REXML::XMLDecl.new("1.0", "UTF-8")
    
    root = document.add_element('xs:schema',
                                { 'xmlns:xs' => "http://www.w3.org/2001/XMLSchema",
                                  'xmlns:ua' => "http://opcfoundation.org/UA/2008/02/Types.xsd",
                                  'xmlns:mtc' => "#{NamespaceUri}/Types.xsd",
                                  'targetNamespace' => "#{NamespaceUri}/Types.xsd",
                                  'elementFormDefault' => "qualified" })
    
    root.add_element('xs:import', { 'namespace' => "http://opcfoundation.org/UA/2008/02/Types.xsd" })

    return document
  end

  def self.type_class
    NodesetType
  end

  def generate_nodeset
    @types.each do |type|
      if type.parent.nil? or type.parent.model != self
        recurse_types(type)
      end
    end
  end

  def recurse_types(type)
    if type.type == 'UMLClass' or type.type == 'UMLStereotype' or
        type.type == 'UMLEnumeration' or type.type == 'UMLDataType' or
        type.type == 'UMLObject'
      type.generate_nodeset
    end

    type.children.each do |t|
      recurse_types(t) if t.model == self
    end
  end  
end
