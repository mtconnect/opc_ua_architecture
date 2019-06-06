# Add directory to path
$: << File.dirname(__FILE__)

require 'optparse'
require 'json'
require 'set'
require 'type'
require 'model'
require 'rexml/document'
require 'rexml/xpath'
require 'nokogiri'

Options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: create_documentation.rb [options] [docs|nodeset]"

  opts.on("-r", "--[no-]clean", "Regenerate Nodeset Ids") do |v|
    Options[:clean] = v
  end
end
parser.parse!


AssetModels = ['Assets', 'Cutting Tool', 'Measurements', 'Assets Profile']

AssetDirectory = 'assets'
AssetDocumentFile = './assets/09-types.tex'
AssetNodesetFile = './Opc.Ua.MTConnect.Assets.Nodeset2.xml'
AssetTypeDictionary = './MTConnect.Assets.TypeDictionary'

DeviceModels = ['Components', 'Component Types', 'Data Items',
            'Conditions', 'Data Item Types', 'Sample Data Item Types',
            'Controlled Vocab Data Item Types', 'Numeric Event Data Item Types',
            'String Event Data Item Types', 'Condition Data Item Types',
            'Data Item Sub Types', 'MTConnect Device Profile']

DeviceDirectory = 'devices'
DeviceDocumentFile = './devices/09-types.tex'
DeviceNodesetFile = './Opc.Ua.MTConnect.Devices.Nodeset2.xml'
DeviceTypeDictionary = './MTConnect.Devices.TypeDictionary'

NodesetFile = './Opc.Ua.MTConnect.Nodeset2.xml'
OpcNodeIdFile = './MTConnect.NodeIds.csv'
TypeDictionary = './MTConnect.TypeDictionary'

xmiDoc = nil
File.open(File.join(File.dirname(__FILE__), '..', 'MTConnect OPC UA EA.xmi')) do |xmi|
  xmiDoc = Nokogiri::XML(xmi).slop!
  xmiDoc.remove_namespaces!
  RootModel = xmiDoc.at('//packagedElement[@type="uml:Package" and @name="Model"]')
end

SkipModels = Set.new
SkipModels.add('Device Example')

unless ARGV.first
  puts "At least one directve docs or nodeset must be given"
  puts parser.help
  exit
end

operations = Set.new(ARGV)

operations.each do |op|
  Type.clear
  Model.clear
  Relation.clear
  
  case op
  when 'docs'
    load 'create_documentation.rb'
    
  when 'nodeset'
    load 'create_nodeset.rb'
    
  else
    puts "Invalid option #{op}"
    puts parser.help
  end
end
