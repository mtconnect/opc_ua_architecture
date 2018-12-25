# Add directory to path
$: << File.dirname(__FILE__)

require 'json'
require 'nodeset_model'
require 'rexml/document'
require 'nokogiri'
require 'time'
require 'id_manager'

Namespace = '1'
NamespaceUri = 'http://opcfoundation.org/UA/MTConnect/v2/'

uml = File.open('MTConnect OPC-UA Devices.mdj').read
doc = JSON.parse(uml)
models = doc['ownedElements'].dup

SkipModels = Set.new
SkipModels.add('UMLStandardProfile')
SkipModels.add('Device Example')

models.each do |e|
  NodesetModel.find_definitions(e)
end

Type.resolve_types
Type.connect_children

puts "\nGenerating Nodeset"

clean = (ARGV.first and ARGV.first == '-r')
p clean

Ids = IdManager.new('MTConnectNodeIds.csv', clean)

document = REXML::Document.new
document << REXML::XMLDecl.new("1.0", "UTF-8")

Root = document.add_element('UANodeSet')
Root.add_namespace('xsd', "http://www.w3.org/2001/XMLSchema")
Root.add_namespace('xsi', "http://www.w3.org/2001/XMLSchema-instance")
Root.add_namespace("http://opcfoundation.org/UA/2011/03/UANodeSet.xsd")

Root.add_attribute("xsi:schemaLocation",
                   "http://opcfoundation.org/UA/2011/03/UANodeSet.xsd UANodeSet.xsd")
                                                                                                                          
Root.add_attribute('LastModified', Time.now.utc.xmlschema)
Root.add_element('NamespaceUris').
  add_element('Uri').
  add_text(NamespaceUri)

Root.add_element('Models').
  add_element('Model',  { 'ModelUri' => NamespaceUri,
                          "Version" => "2.00",
                          "PublicationDate" => Time.now.utc.xmlschema }).
  add_element('RequiredModel', { "ModelUri" => "http://opcfoundation.org/UA/",
                                 "Version" => "1.04",
                                 "PublicationDate" => Time.now.utc.xmlschema } )


# Parse Reference Documents.
if Ids.empty? or clean
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
                            (sym and (sym.value =~ /ModellingRule/o or
                                      sym.value =~ /BinarySchema/o)))
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

TypeDict = REXML::Document.new
TypeDict << REXML::XMLDecl.new("1.0", "UTF-8")

TypeDictRoot = TypeDict.add_element('opc:TypeDictionary', {'DefaultByteOrder' => "LittleEndian",
                                                           'TargetNamespace' => NamespaceUri })
TypeDictRoot.add_namespace('opc', "http://opcfoundation.org/BinarySchema/")
TypeDictRoot.add_namespace('xsi', "http://www.w3.org/2001/XMLSchema-instance")
TypeDictRoot.add_namespace('ua', "http://opcfoundation.org/UA/")
TypeDictRoot.add_namespace('tns', "http://opcfoundation.org/UA/")

TypeDictRoot.add_element('opc:Import', {
                           'Namespace' => "http://opcfoundation.org/UA/",
                           'Location' => "Opc.Ua.BinarySchema.bsd" })

XmlTypeDict = REXML::Document.new
XmlTypeDict << REXML::XMLDecl.new("1.0", "UTF-8")

XmlTypeDictRoot = XmlTypeDict.add_element('xs:schema',
                   { 'xmlns:xs' => "http://www.w3.org/2001/XMLSchema",
                     'xmlns:ua' => "http://opcfoundation.org/UA/2008/02/Types.xsd",
                     'xmlns:mtc' => ="http://opcfoundation.org/UA/MTConnect/Types.xsd",
                     'targetNamespace' => "http://opcfoundation.org/UA/MTConnect/v2/Types.xsd",
                     'elementFormDefault' => "qualified" })

XmlTypeDictRoot.add_ement('xs:import', { 'namespace' => "http://opcfoundation.org/UA/2008/02/Types.xsd" })

NodesetType.resolve_node_ids
NodesetType.check_ids

TypeDictId = Ids.id_for('Opc.Ua.MTConnect')

NodesetModel.generate_nodeset('Namespace Metadata')
NodesetModel.generate_nodeset('Components')
NodesetModel.generate_nodeset('Component Types')
NodesetModel.generate_nodeset('Data Items')
NodesetModel.generate_nodeset('Conditions')
NodesetModel.generate_nodeset('Data Item Types')
NodesetModel.generate_nodeset('Sample Data Item Types')
NodesetModel.generate_nodeset('Condition Data Item Types')
NodesetModel.generate_nodeset('Controlled Vocab Data Item Types')
NodesetModel.generate_nodeset('Numeric Event Data Item Types')
NodesetModel.generate_nodeset('String Event Data Item Types')
NodesetModel.generate_nodeset('Data Item Sub Types')
NodesetModel.generate_nodeset('MTConnect Device Profile')

error = false

puts "Validating all references are resolved"
puts "  Collecting all defined node ids"
node_ids = Set.new
Root.each_element('*') do |e|
  nid = e.attribute('NodeId')
  if nid
    if node_ids.include?(nid.value)
      error = true
      puts "!!!! Node Id #{nid.value} is a duplicate: #{e.inspect}"
    end
    node_ids << nid.value
  end
end

puts "  Checking all references"
Root.each_element('*') do |e|
  nid = e.attribute('DataType')
  if nid and nid.value =~ /^ns=1;/ and !node_ids.include?(nid.value)
    puts "!!!! Data Type NodeId #{nid} is a broken relationship #{e.inspect}"
    error = true
  end
  e.each_element("./References/Reference") do |r|
    if r.text =~ /^ns=1;/ and !node_ids.include?(r.text)
      puts "!!!! Reference #{r.text} is a broken relationship #{r.inspect} of #{e.inspect}"
      error = true
    end
  end
end

if error
  puts "XML is not valid"
#  exit 1
end

formatter = REXML::Formatters::Pretty.new(2)
formatter.compact = true

text = ""
formatter.write(TypeDict, text)
type = Type.type_for_name('Opc.Ua.MTConnect')
type.add_base64_value(text)

File.open('./MTConnect.TypeDictionary.xml', 'w') do |f|
  f << text
end  


File.open('./Opc.Ua.MTConnect.Nodeset2.xml', 'w') do |f|
  formatter.write(document, f)  
end


Ids.save

