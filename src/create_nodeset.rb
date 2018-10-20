# Add directory to path
$: << File.dirname(__FILE__)

require 'json'
require 'nodeset_model'
require 'rexml/document'
require 'nokogiri'
require 'time'

uml = File.open('MTConnect OPC-UA Devices.mdj').read
doc = JSON.parse(uml)
models = doc['ownedElements'].select { |e| e['name'] != 'UMLStandardProfile' }

models.each do |e|
  Model.find_definitions(e)
end

Type.resolve_types
Type.connect_children

puts "\nGenerating Nodeset"

NodeIds = {}
Aliases = {}
Namespace = '1'
NamespaceUri = 'http://opcfoundation.org/UA/MTConnect/v2'


document = REXML::Document.new
document << REXML::XMLDecl.new("1.0", "UTF-8")

root = REXML::Element.new('UANodeSet')
root.add_namespace('xsd', "http://www.w3.org/2001/XMLSchema")
root.add_namespace('xsi', "http://www.w3.org/2001/XMLSchema-instance")
root.add_namespace("http://opcfoundation.org/UA/2011/03/UANodeSet.xsd")

root.add_attribute("xsi:schemaLocation",
                   "http://opcfoundation.org/UA/2011/03/UANodeSet.xsd file:///Z:/projects/MTConnect/OPC-UA/UANodeSet.xsd")
                                                                                                                          
root.add_attribute('LastModified', Time.now.utc.xmlschema)
root.add_element('NamespaceUris').
  add_element('Uri').
  add_text(NamespaceUri)

root.add_element('Models').
  add_element('Model',  { 'ModelUri' => NamespaceUri,
                          "Version" => "2.00",
                          "PublicationDate" => Time.now.utc.xmlschema }).
  add_element('RequiredModel', { "ModelUri" => "http://opcfoundation.org/UA",
                                 "Version" => "1.04",
                                 "PublicationDate" => Time.now.utc.xmlschema } )


# Parse Reference Documents.
once = true

['OPC_UA_Nodesets/Opc.Ua.NodeSet2.xml'].each do |f|

  puts "Parsing OPC UA Nodeset: #{f}"
  File.open(f) do |x|
    doc = REXML::Document.new(x)

    if once
      # Copy aliases
      als = root.add_element('Aliases')
      doc.root.each_element('//Aliases/Alias') do |e|
        Aliases[e.attribute('Alias').value] = e.text
        als.add_element(e)
      end
      once = false
    end

    doc.root.elements.each do |e|
      name, id = e.attribute('BrowseName'), e.attribute('NodeId')
      if name and id
        NodeIds[name.value] = id.value
      end
    end
  end
end

Type.resolve_node_ids
Type.check_ids

Model.generate_nodeset(root, 'Namespace Metadata')
Model.generate_nodeset(root, 'Components')
Model.generate_nodeset(root, 'Data Items')
Model.generate_nodeset(root, 'Conditions')
Model.generate_nodeset(root, 'Data Item Types')
Model.generate_nodeset(root, 'Sample Data Item Types')
Model.generate_nodeset(root, 'Controlled Vocab Data Item Types')
Model.generate_nodeset(root, 'Numeric Event Data Item Types')
Model.generate_nodeset(root, 'String Event Data Item Types')
Model.generate_nodeset(root, 'Data Item Sub Types')
Model.generate_nodeset(root, 'MTConnect Device Profile')

File.open('./MTConnect.Nodeset.xml', 'w') do |f|
  document << root
  formatter = REXML::Formatters::Pretty.new(2)
  formatter.compact = true
  formatter.write(document, f)  
end

