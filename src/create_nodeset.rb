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
NodesetModel.create_id_manager('MTConnectNodeIds.csv', 'MTConnect.NodeIds.csv', Options[:clean])

NodesetModel.skip_models = SkipModels
NodesetModel.new(RootModel).find_definitions

NodesetDocument = NodesetModel.nodeset_document
TypeDict = NodesetModel.type_dict_document
XmlTypeDict = NodesetModel.xml_type_dict_document

NodesetType.resolve_node_ids

puts "Generating nodesets"
NodesetModel.generate_nodeset('Namespace Metadata')
NodesetModel.generate_nodeset('MTConnect Binary')
NodesetModel.generate_nodeset('MTConnect XML Schema')

Models.each do |model|
  puts "Generating #{model}"
  NodesetModel.generate_nodeset(model)
end

error = false

puts "Validating all references are resolved"
puts "  Collecting all defined node ids"
node_ids = Set.new
NodesetModel.root.each_element('*') do |e|
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
NodesetModel.root.each_element('*') do |e|
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

File.open(NodesetFile, 'w') do |f|
  formatter.write(NodesetModel.document, f)  
end

NodesetModel.ids.save

