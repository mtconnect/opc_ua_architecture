# Add directory to path
$: << File.dirname(__FILE__)

require 'nodeset_model'
require 'rexml/document'
require 'nokogiri'
require 'time'
require 'id_manager'

Namespace = '1'
NamespaceUri = 'http://opcfoundation.org/UA/MTConnect/v2/'

puts "\nGenerating Nodeset"

puts "Regenerating based Nodeset Ids" if Options[:clean]
Ids = IdManager.new('MTConnectNodeIds.csv', Options[:clean])

Ids.load_reference_documents(Options[:clean])

UmlModels.each do |e|
  NodesetModel.find_definitions(e)
end

Type.connect_model

NodesetDocument = NodesetModel.nodeset_document
Root = NodesetDocument.root

TypeDict = NodesetModel.type_dict_document
TypeDictRoot = TypeDict.root


XmlTypeDict = NodesetModel.xml_type_dict_document
XmlTypeDictRoot = XmlTypeDict.root

NodesetType.resolve_node_ids

puts "Generating nodesets"
NodesetModel.generate_nodeset('Namespace Metadata')
NodesetModel.generate_nodeset('MTConnect Binary')
NodesetModel.generate_nodeset('MTConnect XML Schema')

Models.each do |model|
  NodesetModel.generate_nodeset(model)
end

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
    elsif r.text.nil?
      puts "!!!! Null reference for #{r.inspect} of #{e.inspect}"
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
type = Type.type_for_name('Opc.Ua.MTConnect(Binary)')
type.add_base64_value(text)

File.open('./MTConnect.TypeDictionary.Binary.xml', 'w') do |f|
  f << text
end  

text = ""
formatter.write(XmlTypeDict, text)
type = Type.type_for_name('Opc.Ua.MTConnect(XML)')
type.add_base64_value(text)

File.open('./MTConnect.TypeDictionary.XML.xml', 'w') do |f|
  f << text
end  


File.open('./Opc.Ua.MTConnect.Nodeset2.xml', 'w') do |f|
  formatter.write(NodesetDocument, f)  
end

Ids.save

