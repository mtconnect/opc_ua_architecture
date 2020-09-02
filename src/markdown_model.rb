require 'markdown_type'
require 'model'

class MarkdownModel < Model
  include Diagram
  include Document

  def self.directory=(dir)
    @@directory = dir
  end

  def self.directory
    @@directory
  end

  def self.type_class
    MarkdownType
  end

  def self.generate_markdown(f, model)
    if @@models[model]
      @@models[model].generate_markdown(f)
    else
      $logger.fatal "Cannot find model: #{model}"
      exit
    end
  end

  def generate_markdown(f)
    file = "model-sections/#{short_name}.md"
    f.puts "{{input(./converted/#{file}.tex)}}"

    File.open("#{@@directory}/#{file}", "w") do |fs|
      $logger.info "Generating model #{@name}"
      fs.puts "{: comment=\"Generated #{Time.now}\" }"
      fs.puts "{{latex(\\clearpage)}}"
      fs.puts "\n## #{@name} {#model:#{short_name}}"
      
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
      return "{{cite(#{@name.sub(/OPC /, '').gsub(' ', '').sub(/Profile/, 'Part5')})}}"
    else
      @name
    end
  end

  def recurse_types(f, type)
    if  type.type == 'uml:Class' or type.type == 'uml:Stereotype' or
        type.type == 'uml:DataType' or type.type == 'uml:AssociationClass'
      type.generate_markdown(f) 
    end

    type.children.each do |t|
      recurse_types(f, t) if t.model == self
    end
  end  
end
