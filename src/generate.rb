# Add directory to path
$: << File.dirname(__FILE__)

require 'optparse'
require 'json'
require 'set'
require 'type'
require 'model'
require 'rexml/document'
require 'rexml/xpath'

Options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: create_documentation.rb [options] [docs|nodeset]"

  opts.on("-a", "--[no-]assets", "Include assets") do |v|
    Options[:assets] = v
  end

  opts.on("-r", "--[no-]clean", "Regenerate Nodeset Ids") do |v|
    Options[:clean] = v
  end
end
parser.parse!


Models = ['Components', 'Component Types', 'Data Items',
          'Conditions', 'Data Item Types', 'Sample Data Item Types',
          'Controlled Vocab Data Item Types', 'Numeric Event Data Item Types',
          'String Event Data Item Types', 'Condition Data Item Types',
          'Data Item Sub Types', 'MTConnect Device Profile']

if (Options[:assets])
  Models << 'Assets'
  Models << 'Cutting Tool'
  Models << 'Assets Profile'
end

xmi = File.open('MTConnect Device EA.xml')
xmiDoc = REXML::Document.new(xmi)

rootModel = REXML::XPath.each(xmiDoc.root, '//packagedElement[@type="uml:Package" and @name="RootModel"]').first

UmlModels = modelRoot.match('//packagedElement[@type="uml:Package"]')


SkipModels = Set.new
SkipModels.add('UMLStandardProfile')
SkipModels.add('Device Example')

load 'create_documentation.rb'

=begin
uml = File.open('MTConnect OPC-UA Devices.mdj').read
umlDoc = JSON.parse(uml)

UmlModels = umlDoc['ownedElements'].dup

SkipModels = Set.new
SkipModels.add('UMLStandardProfile')
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
=end
