# Add directory to path
$: << File.dirname(__FILE__)

require 'json'
require 'latex_model'

uml = File.open('MTConnect OPC-UA Devices.mdj').read
doc = JSON.parse(uml)
models = doc['ownedElements'].select { |e| e['name'] != 'UMLStandardProfile' }
SkipModels = Set.new

models.each do |e|
  LatexModel.find_definitions(e)
end

LatexType.resolve_types
LatexType.connect_children


puts "\nGenerating LaTex"

File.open('./assets/09-types.tex', 'w') do |f|
  f.puts "% Generated #{Time.now}"
  
  LatexModel.generate_latex(f, 'CuttingTool')
  LatexModel.generate_latex(f, 'AssetsProfile')
end
