require 'json'
require 'latex_model'

LatexModel.skip_models = SkipModels
LatexModel.new(RootModel).find_definitions

puts "\nGenerating LaTex to #{DocumentFile}"
File.open(DocumentFile, 'w') do |f|
  f.puts "% Generated #{Time.now}"

  Models.each do |m|
    LatexModel.generate_latex(f, m)
  end
end
