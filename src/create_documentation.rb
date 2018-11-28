# Add directory to path
$: << File.dirname(__FILE__)

require 'json'
require 'latex_model'

uml = File.open('MTConnect OPC-UA Devices.mdj').read
doc = JSON.parse(uml)
models = doc['ownedElements'].select { |e| e['name'] != 'UMLStandardProfile' }

models.each do |e|
  LatexModel.find_definitions(e)
end

LatexType.resolve_types
LatexType.connect_children


puts "\nGenerating LaTex"

File.open('./latex/types.tex', 'w') do |f|
  f.puts "% Generated #{Time.now}"
  
  LatexModel.generate_latex(f, 'Components')
  LatexModel.generate_latex(f, 'Component Types')
  LatexModel.generate_latex(f, 'Data Items')
  LatexModel.generate_latex(f, 'Conditions')
  LatexModel.generate_latex(f, 'Data Item Types')
  LatexModel.generate_latex(f, 'Sample Data Item Types')
  LatexModel.generate_latex(f, 'Controlled Vocab Data Item Types')
  LatexModel.generate_latex(f, 'Numeric Event Data Item Types')
  LatexModel.generate_latex(f, 'String Event Data Item Types')
  LatexModel.generate_latex(f, 'Condition Data Item Types')
  LatexModel.generate_latex(f, 'Data Item Sub Types')
#  Model.generate_latex(f, 'Factories')
  LatexModel.generate_latex(f, 'MTConnect Device Profile')
  
end
