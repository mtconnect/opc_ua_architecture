# Add directory to path
$: << File.dirname(__FILE__)

require 'nodeset_model'
require 'rexml/document'
require 'nokogiri'
require 'time'
require 'id_manager'

Namespace = '1'
NamespaceUri = 'http://opcfoundation.org/UA/MTConnect/v2/'

$logger.info "\nGenerating Nodeset"

$logger.warn "Regenerating based Nodeset Ids" if Options[:clean]
NodesetModel.create_id_manager('MTConnectNodeIds.csv', OpcNodeIdFile, Options[:clean])

NodesetModel.skip_models = SkipModels
NodesetModel.new(RootModel).find_definitions

NodesetType.resolve_node_ids


def create_nodeset(models, nodesetFile, typeDictionary)
  NodesetModel.nodeset_document
  typeDict = NodesetModel.type_dict_document
  xmlTypeDict = NodesetModel.xml_type_dict_document

  $logger.info "Generating nodesets"
  NodesetModel.generate_nodeset('Namespace Metadata')
  NodesetModel.generate_nodeset('MTConnect Binary')
  NodesetModel.generate_nodeset('MTConnect XML Schema')

  models.each do |model|
    $logger.info "Generating #{model}"
    NodesetModel.generate_nodeset(model)
  end

  error = false
  
  $logger.info "Validating all references are resolved"
  $logger.info "  Collecting all defined node ids"
  node_ids = Set.new
  NodesetModel.root.each_element('*') do |e|
    nid = e.attribute('NodeId')
    if nid
      if node_ids.include?(nid.value)
        error = true
        $logger.error "!!!! Node Id #{nid.value} is a duplicate: #{e.inspect}"
      end
      node_ids << nid.value
    end
  end
  
  $logger.info "  Checking all references"
  NodesetModel.root.each_element('*') do |e|
    nid = e.attribute('DataType')
    if nid and nid.value =~ /^ns=1;/ and !node_ids.include?(nid.value)
      $logger.error "!!!! Data Type NodeId #{nid} is a broken relationship #{e.inspect}"
      error = true
    end
    e.each_element("./References/Reference") do |r|
      if r.text =~ /^ns=1;/ and !node_ids.include?(r.text)
        $logger.error "!!!! Reference #{r.text} is a broken relationship #{r.inspect} of #{e.inspect}"
        error = true
      elsif r.text.nil?
        $logger.error "!!!! Null reference for #{r.inspect} of #{e.inspect}"
        error = true
      end
    end
  end
  
  if error
    $logger.error "XML is not valid"
    #  exit 1
  end
  
  formatter = REXML::Formatters::Pretty.new(2)
  formatter.compact = true
  text = ""
  formatter.write(typeDict, text)
  type = Type.type_for_name('Opc.Ua.MTConnect(Binary)')
  type.add_base64_value(text)
  
  File.open("./#{typeDictionary}.Binary.xml", 'w') do |f|
    f << text
  end  
  
  text = ""
  formatter.write(xmlTypeDict, text)
  type = Type.type_for_name('Opc.Ua.MTConnect(XML)')
  type.add_base64_value(text)
  
  File.open("./#{typeDictionary}.XML.xml", 'w') do |f|
    f << text
  end  
  
  File.open(nodesetFile, 'w') do |f|
    formatter.write(NodesetModel.document, f)  
  end
end

create_nodeset(DeviceModels, DeviceNodesetFile, DeviceTypeDictionary)
create_nodeset(AssetModels, AssetNodesetFile, AssetTypeDictionary)
create_nodeset(DeviceModels + AssetModels, NodesetFile, TypeDictionary)
  
NodesetModel.ids.save

