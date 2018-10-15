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

Type.connect_children

puts "\nGenerating Nodeset"

document = REXML::Document.new
document << REXML::XMLDecl.new("1.0", "UTF-8")

root = REXML::Element.new('UANodeSet')
root.add_namespace('xsd', "http://www.w3.org/2001/XMLSchema")
root.add_namespace('xsi', "http://www.w3.org/2001/XMLSchema-instance")
root.add_namespace("http://opcfoundation.org/UA/2011/03/UANodeSet.xsd")

root.add_attribute('LastModified', Time.now.utc.xmlschema)
root.add_element('NamespaceUris').
  add_element('Uri').
  add_text('http://opcfoundation.org/UA/MTConnect/')

root.add_element('Models').
  add_element('Model',  { 'ModelUri' => "http://opcfoundation.org/UA/MTConnect/",
                          "Version" => "1.00",
                          "PublicationDate" => Time.now.utc.xmlschema }).
  add_element('RequiredModel', { "ModelUri" => "http://opcfoundation.org/UA/",
                                 "Version" => "1.03",
                                 "PublicationDate" => Time.now.utc.xmlschema } )


NodeIds = {}
Aliases = {}

# Parse Reference Documents.
once = true

['OPC_UA_Nodesets/Opc.Ua.NodeSet2.Part3.xml',
 'OPC_UA_Nodesets/Opc.Ua.NodeSet2.Part5.xml',
 'OPC_UA_Nodesets/Opc.Ua.NodeSet2.Part8.xml',
 'OPC_UA_Nodesets/Opc.Ua.NodeSet2.Part9.xml'].each do |f|

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
    
    ['UAObject', 'UAObjectType', 'UAVariable', 'UAVariableType', 'UADataType'].each do |node|
      doc.root.each_element("//#{node}") do |e|
        NodeIds[e.attribute('BrowseName').value] =  e.attribute('NodeId').value
      end
    end  
  end
end

# Copy Namespace Pre-amble
File.open(File.join(File.dirname(__FILE__), 'preamble.xml')) do |f|
  doc = REXML::Document.new(f)
  doc.root.each_element do |e|
    root.add_element(e)
  end
end

Type.check_ids

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

