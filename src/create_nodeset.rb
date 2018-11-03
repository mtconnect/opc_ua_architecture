# Add directory to path
$: << File.dirname(__FILE__)

require 'json'
require 'nodeset_model'
require 'rexml/document'
require 'nokogiri'
require 'time'
require 'id_manager'

uml = File.open('MTConnect OPC-UA Devices.mdj').read
doc = JSON.parse(uml)
models = doc['ownedElements'].select { |e| e['name'] != 'UMLStandardProfile' }

models.each do |e|
  Model.find_definitions(e)
end

Type.resolve_types
Type.connect_children

puts "\nGenerating Nodeset"

Ids = IdManager.new('MTConnectNodeIds.csv')
Namespace = '1'
NamespaceUri = 'http://opcfoundation.org/UA/MTConnect/v2'


document = REXML::Document.new
document << REXML::XMLDecl.new("1.0", "UTF-8")

Root = REXML::Element.new('UANodeSet')
Root.add_namespace('xsd', "http://www.w3.org/2001/XMLSchema")
Root.add_namespace('xsi', "http://www.w3.org/2001/XMLSchema-instance")
Root.add_namespace("http://opcfoundation.org/UA/2011/03/UANodeSet.xsd")

Root.add_attribute("xsi:schemaLocation",
                   "http://opcfoundation.org/UA/2011/03/UANodeSet.xsd file:///Z:/projects/MTConnect/OPC-UA/UANodeSet.xsd")
                                                                                                                          
Root.add_attribute('LastModified', Time.now.utc.xmlschema)
Root.add_element('NamespaceUris').
  add_element('Uri').
  add_text(NamespaceUri)

Root.add_element('Models').
  add_element('Model',  { 'ModelUri' => NamespaceUri,
                          "Version" => "2.00",
                          "PublicationDate" => Time.now.utc.xmlschema }).
  add_element('RequiredModel', { "ModelUri" => "http://opcfoundation.org/UA",
                                 "Version" => "1.04",
                                 "PublicationDate" => Time.now.utc.xmlschema } )


# Parse Reference Documents.
if Ids.empty?
  ['OPC_UA_Nodesets/Opc.Ua.NodeSet2.xml'].each do |f|
    puts "Parsing OPC UA Nodeset: #{f}"
    File.open(f) do |x|
      doc = REXML::Document.new(x)
      
      # Copy aliases
      doc.root.each_element('//Aliases/Alias') do |e|
        Ids.add_alias(e.attribute('Alias').value)
      end
      
      doc.root.elements.each do |e|
        parent, name, id, sym = e.attribute('ParentNodeId'), e.attribute('BrowseName'), e.attribute('NodeId'),
          e.attribute('SymbolicName')

        if name and id and (e.name =~ /Type$/o or
                (sym and sym.value =~ /ModellingRule/o) or
                (name.value == 'Namespaces'))
          Ids[name.value] = id.value 
        end
      end
    end
  end
  
  Ids.save
end

als = Root.add_element('Aliases')
Ids.each_alias do |a|
  als.add_element('Alias', { 'Alias' => a }).add_text(Ids.raw_id(a))
end

Type.resolve_node_ids
Type.check_ids

Model.generate_nodeset('Namespace Metadata')
Model.generate_nodeset('Components')
Model.generate_nodeset('Data Items')
Model.generate_nodeset('Conditions')
Model.generate_nodeset('Data Item Types')
Model.generate_nodeset('Sample Data Item Types')
Model.generate_nodeset('Condition Data Item Types')
Model.generate_nodeset('Controlled Vocab Data Item Types')
Model.generate_nodeset('Numeric Event Data Item Types')
Model.generate_nodeset('String Event Data Item Types')
Model.generate_nodeset('Data Item Sub Types')
Model.generate_nodeset('MTConnect Device Profile')

File.open('./MTConnect.Nodeset2.xml', 'w') do |f|
  document << Root
  formatter = REXML::Formatters::Pretty.new(2)
  formatter.compact = true
  formatter.write(document, f)  
end

Ids.save

