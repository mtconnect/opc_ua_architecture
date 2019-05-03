require 'json'
require 'latex_model'

LatexModel.skip_models = SkipModels
LatexModel.new(RootModel).find_definitions

puts "\nGenerating LaTex"
File.open('./latex/09-types.tex', 'w') do |f|
  f.puts "% Generated #{Time.now}"

  Models.each do |m|
    LatexModel.generate_latex(f, m)
  end
end
