# Add directory to path
$: << File.dirname(__FILE__)

require 'optparse'
require 'json'
require 'set'

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

uml = File.open('MTConnect OPC-UA Devices.mdj').read
umlDoc = JSON.parse(uml)
UmlModels = umlDoc['ownedElements'].dup

SkipModels = Set.new
SkipModels.add('UMLStandardProfile')
SkipModels.add('Device Example')

if ARGV[0] == 'docs'
  load 'create_documentation.rb'
elsif ARGV[0] == 'nodeset'
  load 'create_nodeset.rb'
else
  puts parser.help
end
