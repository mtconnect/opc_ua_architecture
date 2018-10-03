# Add directory to path
$: << File.dirname(__FILE__)

require 'json'
require 'model'

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
  Model.generate_latex(f, 'Factories')
  Model.generate_latex(f, 'MTConnect Device Profile')
  
end
