require 'latex_type'
require 'model'

class LatexModel < Model
  include Diagram
  include Document

  def self.directory=(dir)
    @@directory = dir
  end

  def self.directory
    @@directory
  end

  def self.type_class
    LatexType
  end

  def self.generate_latex(f, model)
    if @@models[model]
      @@models[model].generate_latex(f)
    else
      puts "Cannot find model: #{model}"
      exit
    end
  end

  def generate_latex(f)
    file = "./model-sections/#{short_name}.tex"
    f.puts "\\input #{file}"

    File.open("#{@@directory}/#{file}", "w") do |fs|
      puts "Generating model #{@name}"
      fs.puts "% Generated #{Time.now}"
      fs.puts "\\subsection{#{@name}} \\label{model:#{short_name}}"
      
      generate_diagram(fs)
      
      generate_documentation(fs)
      
      @types.each do |type|
        if type.parent.nil? or type.parent.model != self
          recurse_types(fs, type)
        end
      end
    end
  end

  def reference
    if @name =~ /OPC/
      return "\\cite{#{@name.sub(/OPC /, '').gsub(' ', '').sub(/Profile/, 'Part5')}}"
    else
      @name
    end
  end

  def recurse_types(f, type)
    if  type.type == 'uml:Class' or type.type == 'uml:Stereotype' or
        type.type == 'uml:DataType' or type.type == 'uml:AssociationClass'
      type.generate_latex(f) 
    end

    type.children.each do |t|
      recurse_types(f, t) if t.model == self
    end
  end  
end
