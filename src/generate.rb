# Add directory to path
$: << File.dirname(__FILE__)

require 'logger'
require 'optparse'
require 'json'
require 'set'
require 'type'
require 'model'
require 'rexml/document'
require 'rexml/xpath'
require 'nokogiri'

require 'treetop'
require 'latex_parser'

Options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: generate.rb [options] [docs|nodeset]"

  opts.on("-r", "--[no-]clean", "Regenerate Nodeset Ids") do |v|
    Options[:clean] = v
  end

  opts.on('-d', '--[no-]debug', 'Debug logging') do |v|
    Options[:debug] = v
  end
end
parser.parse!

$logger = Logger.new(STDOUT)
$logger.level = Options[:debug] ? Logger::DEBUG : Logger::INFO 
$logger.formatter = proc do |severity, datetime, progname, msg|
  "#{severity}: #{msg}\n"
end

Glossary = LatexParser.new
Glossary.parse_glossary('mtc-terms.tex')

NodesetFile = './Opc.Ua.MTConnect.NodeSet2.xml'
OpcNodeIdFile = './MTConnect.NodeIds.csv'
TypeDictionary = './MTConnect.TypeDictionary'

DeviceModels = ['Components', 'Component Types', 'Data Items',
            'Conditions', 'Data Item Types', 'Sample Data Item Types',
            'Controlled Vocab Data Item Types', 'Numeric Event Data Item Types',
            'String Event Data Item Types', 'Condition Data Item Types',
            'Data Item Sub Types', 'MTConnect Device Profile']

DeviceDirectory = 'devices'
DeviceDocumentFile = './devices/09-types.tex'
DeviceNodesetFile = './Opc.Ua.MTConnect.NodeSet2.Part1.xml'
DeviceTypeDictionary = './MTConnect.Devices.TypeDictionary'

AssetModels = [] # ['Assets', 'Cutting Tool', 'Measurements', 'Assets Profile']

AssetDirectory = 'assets'
AssetDocumentFile = './assets/09-types.tex'
AssetNodesetFile = './Opc.Ua.MTConnect.NodeSet2.Part2.xml'
AssetTypeDictionary = './MTConnect.Assets.TypeDictionary'

xmiDoc = nil
File.open(File.join(File.dirname(__FILE__), '..', 'MTConnect OPC UA MD Clean.xml')) do |xmi|
  xmiDoc = Nokogiri::XML(xmi).slop!
  RootModel = xmiDoc.at('//uml:Model')
end

$namespaces = Hash[xmiDoc.namespaces.map { |k, v| [k.split(':').last, v] }]

SkipModels = Set.new
SkipModels.add('Device Example')
SkipModels.add('Streaming Events')
SkipModels.add('MTConnectAssets')

unless ARGV.first
  $logger.error "At least one directve docs or nodeset must be given"
  $logger.error parser.help
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
    $logger.error "Invalid option #{op}"
    $logger.fatal parser.help
  end
end
