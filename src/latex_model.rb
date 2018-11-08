require 'latex_type'
require 'model'

class LatexModel < Model
  include Diagram
  include Document

  def self.type_class
    LatexType
  end

  def self.generate_latex(f, model)
    @@models[model].generate_latex(f)
  end

  def generate_latex(f)
    f.puts "\\subsection{#{@name}} \\label{model:#{short_name}}"

    generate_diagram(f)

    generate_documentation(f)

    @types.each do |type|
      if type.parent.nil? or type.parent.model != self
        recurse_types(f, type)
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
    if type.type == 'UMLClass' or
        type.type == 'UMLStereotype' or
        type.type == 'UMLDataType'
      type.generate_latex(f) 
    end

    type.children.each do |t|
      recurse_types(f, t) if t.model == self
    end
  end  
end
