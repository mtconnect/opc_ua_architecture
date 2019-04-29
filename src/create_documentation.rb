require 'json'
require 'latex_model'

UmlModels.each do |e|
  LatexModel.find_definitions(e)
end

=begin
Type.connect_model

puts "\nGenerating LaTex"
File.open('./latex/09-types.tex', 'w') do |f|
  f.puts "% Generated #{Time.now}"

  Models.each do |m|
    LatexModel.generate_latex(f, m)
  end
end
=end
