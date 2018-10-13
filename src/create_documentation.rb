# Add directory to path
$: << File.dirname(__FILE__)

require 'json'
require 'latex_model'

uml = File.open('MTConnect OPC-UA Devices.mdj').read
doc = JSON.parse(uml)
models = doc['ownedElements'].select { |e| e['name'] != 'UMLStandardProfile' }

models.each do |e|
  Model.find_definitions(e)
end

Type.connect_children

puts "\nGenerating LaTex"

File.open('./latex/types.tex', 'w') do |f|
  f.puts "% Generated #{Time.now}"
  
  Model.generate_latex(f, 'Components')
  Model.generate_latex(f, 'Data Items')
  Model.generate_latex(f, 'Conditions')
  Model.generate_latex(f, 'Data Item Types')
  Model.generate_latex(f, 'Sample Data Item Types')
  Model.generate_latex(f, 'Controlled Vocab Data Item Types')
  Model.generate_latex(f, 'Numeric Event Data Item Types')
  Model.generate_latex(f, 'String Event Data Item Types')
  Model.generate_latex(f, 'Data Item Sub Types')
  Model.generate_latex(f, 'Factories')
  Model.generate_latex(f, 'MTConnect Device Profile')
  
end
