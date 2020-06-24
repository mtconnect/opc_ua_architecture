require 'nodeset_type'
require 'model'
require 'id_manager'
require 'time'
require 'rexml/document'


class NodesetModel < Model

  def self.generate_nodeset(model)
    @@models[model].generate_nodeset
  end

  def self.root
    @@root
  end

  def self.document
    @@document
  end

  def self.create_id_manager(file, opc_file, clean)
    @@ids = IdManager.new(file, opc_file, clean)
    @@ids.load_reference_documents(clean)
  end

  def self.ids
    @@ids
  end

  def self.nodeset_document
    @@document = REXML::Document.new
    @@document << REXML::XMLDecl.new("1.0", "UTF-8")
    
    @@root = document.add_element('UANodeSet')
    @@root.add_namespace('xsd', "http://www.w3.org/2001/XMLSchema")
    @@root.add_namespace('xsi', "http://www.w3.org/2001/XMLSchema-instance")
    @@root.add_namespace("http://opcfoundation.org/UA/2011/03/UANodeSet.xsd")

    @@root.add_attribute("xsi:schemaLocation",
                   "http://opcfoundation.org/UA/2011/03/UANodeSet.xsd UANodeSet.xsd")
                                                                                                                          
    @@root.add_attribute('LastModified', Time.now.utc.xmlschema)
    @@root.add_element('NamespaceUris').
      add_element('Uri').
      add_text(NamespaceUri)

    @@root.add_element('Models').
      add_element('Model',  { 'ModelUri' => NamespaceUri,
                              "Version" => "2.00.01",
                              "PublicationDate" => "2020-06-05T00:00:00Z" }).
      add_element('RequiredModel', { "ModelUri" => "http://opcfoundation.org/UA/",
                                     "Version" => @@ids.version,
                                     "PublicationDate" => @@ids.pub_date } )

    # Add aliases
    als = @@root.add_element('Aliases')
    @@ids.each_alias do |a|
      als.add_element('Alias', { 'Alias' => a }).add_text(@@ids.raw_id(a))
    end

    return @@document
  end

  def self.type_dict
    @@type_dict
  end

  def self.type_dict_root
    @@type_dict_root
  end

  def self.type_dict_document
    @@type_dict = REXML::Document.new
    @@type_dict << REXML::XMLDecl.new("1.0", "UTF-8")

    @@type_dict_root = @@type_dict.add_element('opc:TypeDictionary', {'DefaultByteOrder' => "LittleEndian",
                                                           'TargetNamespace' => NamespaceUri })
    @@type_dict_root.add_namespace('opc', "http://opcfoundation.org/BinarySchema/")
    @@type_dict_root.add_namespace('xsi', "http://www.w3.org/2001/XMLSchema-instance")
    @@type_dict_root.add_namespace('ua', "http://opcfoundation.org/UA/")
    @@type_dict_root.add_namespace('tns', "http://opcfoundation.org/UA/")

    @@type_dict_root.add_element('opc:Import', {
                       'Namespace' => "http://opcfoundation.org/UA/",
                       'Location' => "Opc.Ua.BinarySchema.bsd" })

    return @@type_dict
  end

  def self.xml_type_dict
    @@xml_type_dict
  end
  
  def self.xml_type_dict_root
    @@xml_type_dict_root
  end

  def self.xml_type_dict_document
    @@xml_type_dict = REXML::Document.new
    @@xml_type_dict << REXML::XMLDecl.new("1.0", "UTF-8")
    
    @@xml_type_dict_root = @@xml_type_dict.add_element('xs:schema',
                                { 'xmlns:xs' => "http://www.w3.org/2001/XMLSchema",
                                  'xmlns:ua' => "http://opcfoundation.org/UA/2008/02/Types.xsd",
                                  'xmlns:mtc' => "#{NamespaceUri}/Types.xsd",
                                  'targetNamespace' => "#{NamespaceUri}/Types.xsd",
                                  'elementFormDefault' => "qualified" })
    
    @@xml_type_dict_root.add_element('xs:import', { 'namespace' => "http://opcfoundation.org/UA/2008/02/Types.xsd" })

    return @@xml_type_dict
  end

  def self.type_class
    NodesetType
  end

  def generate_nodeset
    $logger.info "Generating model #{@name}"
    @types.each do |type|
      if type.parent.nil? or type.parent.model != self
        recurse_types(type)
      end
    end
  end

  def recurse_types(type)
    if type.type == 'uml:Class' or type.type == 'uml:Stereotype' or
        type.type == 'uml:Enumeration' or type.type == 'uml:DataType' or
        type.type == 'uml:Object' or type.type == 'uml:InstanceSpecification'
      type.generate_nodeset
    end

    type.children.each do |t|
      recurse_types(t) if t.model == self
    end
  end  
end
