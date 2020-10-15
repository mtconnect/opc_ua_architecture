require 'type'
require 'set'

module Diagram
  def png_diagram_name
    "./diagrams/types/#{short_name}.png"
  end

  def tex_diagram_name
    "./diagrams/types/#{short_name}.tex"
  end

  def png_diagram_file_name
    "./#{MarkdownModel.directory}/#{png_diagram_name}"
  end

  def tex_diagram_file_name
    "./#{MarkdownModel.directory}/#{tex_diagram_name}"
  end

  def png_diagram_exists?
    File.exists?(png_diagram_file_name)      
  end

  def tex_diagram_exists?
    File.exists?(tex_diagram_file_name)
  end
  
  def generate_diagram(f)
    if tex_diagram_exists?
      # puts "** Generating png diagrams #{tex_diagram_file_name}"

      f.puts "{{input(#{tex_diagram_name})}}\n\n"
    elsif png_diagram_exists?
      # puts "** Generating png diagrams #{png_diagram_file_name}"
      f.puts "![#{@name} Diagram](#{png_diagram_name} \"#{short_name}\")\n\n{{FloatBarrier}}\n\n"
    end
  end
end

module Document
  def documentation_name
    "./type-sections/#{short_name}.md.tex"
  end

  def documentation_file_name
    "./#{MarkdownModel.directory}/#{documentation_name}"
  end


  def documentation_exists?
    File.exists?(documentation_file_name)
  end

  def generate_documentation(f)
    if documentation_exists?
      f.puts "{{input(#{documentation_name})}}\n\n"
    elsif @documentation
      f.puts "\n#{@documentation.gsub(/^```/, '~~~~')}\n\n"
    end
  end
end

class MarkdownType < Type
  include Diagram
  include Document

  @@labels = Set.new

  ROW_FORMAT = %s{format-1="p 0.85in" format-2="p 0.8in" format-3="p 1.3in" format-4="p 1.3in" format-5="p 0.85in" format-6="p 0.5in"}

  def reference
    "See section {{block(#{@name})}}"
  end
  
  def generate_supertype(f)
    parent = get_parent
    if parent
      if parent.model != @model
        ref = "See #{parent.model.reference} Documentation"
      else
        ref = parent.reference
      end
      f.puts "| {{span(6)}} Subtype of #{parent.name} (#{ref}) |"
    end
  end

  def mixin_relations(f)
    @parent.mixin_relations(f) if @parent
    generate_relations(f)
  end

  def hyphenate(s)
    s.gsub(/([a-z])([A-Z])/, '\1\\-\2').
      gsub(/(MT)([A-Z])/, '\1\\-\2')
  end

  

  def generate_relations(f)
    # puts "Generating relations for #{@name}"
    @relations.each do |r|
      if r.is_reference?
        begin
          # puts "  Ref: '#{r.name}' '#{r.stereotype}' '#{r.final_target.type.name}' #{r.target_node_name} #{r.is_derived?}"
          next if r.is_derived? or (r.stereotype and r.stereotype =~ /Attribute/)  
          
          array = '\\[\\]' if r.is_array?
          
          if r.is_property? or r.is_folder?
            type_info = "#{r.final_target.type.name}#{array} | #{r.target_node_name}"
          elsif r.target.type.is_variable?
            type_info = "#{r.target.type.variable_data_type.name}#{array} | #{r.target_node_name}"
          else
            type_info = "{{span(2)}} #{r.target_node_name}#{array}"
          end

          f.puts "| #{r.reference_type} | #{r.target.type.base_type} | #{r.browse_name} | #{type_info} | #{r.rule} |"
        rescue
          $logger.error "#{$!}: #{@name}::#{r.name} #{r.final_target.name} #{r.final_target.type_id} #{r.final_target.type}"
          raise 
        end
      end
    end
  end

  def escape_name_code
    escape_name.gsub(/\\/, '')
  end

      

  def generate_constraints(f, obj = self)
    unless obj.constraints.empty?
      f.puts "#### Constraints\n\n"
      obj.constraints.each do |c|
        f.puts "* Constraint `#{c.name}`: `#{c.specification}`"
        f.puts "  * Documentation: #{c.documentation}" if c.documentation
      end
    end

    unless obj.invariants.empty?
      f.puts "#### Static values for #{obj.name}\n"

      f.puts <<EOT
| Name | Value |
|------|-------|
EOT

      obj.invariants.each do |name, value|
        f.puts "| `#{name}` | `#{value}` |"
      end
      
      f.puts %s{: caption="`#{escape_name_code}::#{obj.name}` Values"\n\n}
      
      obj.invariants.each do |k, v|
        f.puts "* Property `#{k}`: `#{v}`"
      end
    end

    if obj.equal?(self)
      @relations.each do |r|
        generate_constraints(f, r)
      end
    end
  end

  def generate_subtype(f, c)
    t = c.is_a_type?('BaseVariableType') ? 'VariableType' : 'ObjectType'
    f.puts "| HasSubtype | #{t} | #{c.escape_name} | {{span(3)}} #{c.reference} |"
  end

  def generate_children(f)
    cs = @children.dup.select { |t| t.model.name !~ /Example/ }
    cs.each do |c|
      generate_subtype(f, c)
    end
  end

  def generate_attribute_docs(f, header)
    $logger.info "Generating docs for #{@name}"
    relations_with_documentation =
      @relations.select do |r|
        $logger.debug "  Looking for docs for #{r.target.inspect}" if r.target.type.nil?
        r.documentation or r.target.type.type == 'uml:Enumeration'
      end

    unless relations_with_documentation.empty?
      f.puts "\n{{FloatBarrier}}"
      f.puts "\n#### #{header}\n\n"
      relations_with_documentation.each do |r|
        if r.documentation
          f.puts "* `#{r.name} : #{r.final_target.type.name}`: #{r.documentation}"
        end
        
        if r.target.type.type == 'uml:Enumeration'
          f.puts "* **Allowable Values** for `#{r.target.type.name}`"
          f.puts "\n{{FloatBarrier}}\n\n"
          r.target.type.generate_enumerations(f)
          f.puts "\n{{FloatBarrier}}\n\n"
        end
      end
      f.puts
    end

    
  end
  
  def generate_operations(f)
    if !@operations.empty?
      f.puts "\n#### Operations"
      
      @operations.each do |name, docs|
        f.print "* `#{name}()`"
        if false
          f.puts "\\\\\n    Specification:"
          f.puts "   \\indent \\begin{lstlisting}"
          f.puts specs
          f.puts "\\end{lstlisting}"          
        end
        if docs
          f.puts "<br/> Documentation: #{docs}"
        end
        f.puts
      end
    end
  end

  def generate_type_table(f)
    f.puts <<EOT
| Attribute  | Value    |
|------------|----------|
| BrowseName | #{@name} |
| IsAbstract | #{@abstract.to_s.capitalize} |
EOT

    if is_variable?
      v = get_attribute_like('ValueRank')
      f.puts "| ValueRank | #{v.default} |"
      a = get_attribute_like('DataType') || 'BaseVariableType'
      f.puts "| DataType | #{a.target.type.name} |"
    elsif is_reference?
      a = get_attribute_like('Symmetric')
      t = a.default || 'false'
      f.puts "| Symmetric | #{t} |"
    end
    f.puts <<EOT
{: caption="`#{escape_name_code}` Definition" label="#{@name}" format-1="p 0.85in" format-2="p 5.425in" }

EOT
    
    f.puts <<EOT

| References | NodeClass | BrowseName | DataType | Type-Definition   | Modeling-Rule   |
|------------|-----------|------------|----------|-------------------|-----------------|
EOT
    
    generate_supertype(f)
    generate_children(f)

    @mixin.mixin_relations(f) if @mixin
    
    generate_relations(f)

    f.puts "{: #{ROW_FORMAT} }\n\n"
  end

  def generate_enumerations(f)
    if @type == 'uml:Enumeration'
      $logger.debug "***** =====> Generating Enumerations for #{@name}"
      
      generate_documentation(f)

      unless @@labels.include?(@name)
        label = "label=\"enum:#{@name}\""
        @@labels.add(@name)
      end

      f.puts <<EOT

| Name | Index | Description |
|------|------:|-------------|
EOT

      @literals.each do |lit|
        f.puts "|`#{lit.name}` | `#{lit.value}` | #{lit.description} |"
      end
        
      f.puts "{: format-3=\"p 3in\" caption=\"`#{escape_name_code}` Enumeration\" #{label} }"
    end
  end

  def generate_dependencies(f)

    deps = dependencies.select { |d|
      d.target.type.stereotype.nil? or not (d.target.type.stereotype =~ /Factory/)
    }

    if !deps.empty? or @mixin
      f.puts "\n#### Dependencies and Relationships"

      deps.each do |dep|
        target = dep.target
        
        if dep.stereotype and dep.stereotype == 'values' and
            target.type.type == 'uml:Enumeration'
          
          f.puts "\n##### **Allowable Values** for `#{target.type.name}`"
          f.puts "\n{{FloatBarrier}}"
          target.type.generate_enumerations(f)
          f.puts "\n{{FloatBarrier}}"
        else
          f.puts "\n##### Dependency on `#{target.type.name}`"
          rel = dep.stereotype && dep.stereotype
          if rel
            f.puts "This class relates to `#{target.type.name}` (#{target.type.reference}) for a(n) `#{rel}` relationship.\n\n"
          else
            $logger.error "Cannot find stereo for #{@name}::#{dep.name} to #{target.type.name}"
          end
        end
      end
    
      f.puts "\n##### Mixes in `#{@mixin.escape_name_code}`, see #{@mixin.reference}" if @mixin
    end
  end

  def generate_data_type(f)
    
    f.puts <<EOT
| Field | Type | Optional |
|-------|------|----------|
EOT
    
      @relations.each do |r|
        array = '\\[\\]' if r.is_array?
        optional = r.is_optional? ? 'Optional' : 'Mandatory'
        f.puts "| `#{r.name}` | `#{r.target.type.name}#{array}` | `#{optional}` |"
      end
        
      f.puts "{: caption=\"`#{escape_name_code}` DataType\" label=\"data-type:#{@name}\" }"

      generate_attribute_docs(f, "Data Type Fields")
  end

  def generate_class_diagram
    raise "unused"
    
    File.open("./#{MarkdownModel.directory}/classes/#{@name.gsub(/[<>]/, '-')}.tex", 'w') do |f|
      if @abstract
        f.puts "\\umlabstract{#{@name}}{"
      else
        f.puts "\\umlclass{#{@name}}{"
      end

      @relations.each do |r|
        if r.is_property?
          if r.stereotype
            stereo = "<<#{r.stereotype}>> "
          end
          f.puts "#{stereo}+ #{r.name}: #{r.target.type.name}#{r.is_optional? ? '[0..1]' : ''} \\\\"
        end
      end
      
      f.puts "}{}"
      f.puts "\n% Relationships\n\n"
      
      @relations.each do |r|
        if !r.is_property?
          if r.stereotype
            stereo = "stereo=#{r.stereotype},"
          end
          case r
          when Relation::Generalization
            f.puts "\\umlinherit[geometry=|-|]{#{r.source.type.name}}{#{r.target.type.name}}"

          when Relation::Association
            f.puts <<EOT
\\umluniassoc[geometry=|-,#{stereo}%
              arg1=#{r.name},%
              mult1=#{r.source.multiplicity},%
              mult2=#{r.target.multiplicity}]{#{r.source.type.name}}{#{r.target.type.name}}
EOT
          end
        end
      end
    end
  end

  def generate_class(f)
    if stereotype_name !~ /Factory/o and (is_a_type?('References') or @model.name !~ /Profile/)
      generate_type_table(f) 
    end
    
    generate_attribute_docs(f, "Referenced Properties and Objects")
    generate_operations(f)
    generate_constraints(f)
    generate_dependencies(f)    
  end
     
  def generate_markdown(f = STDOUT)
    # puts "--- Generating #{@name} #{@stereotype}"
    return if @name =~ /Factory/ or @stereotype =~ /metaclass/

    stereo = "`#{stereotype_name}`" if stereotype_name and !stereotype_name.empty?

    f.puts <<EOT

### Defintion of #{stereo} `#{escape_name_code}` {#type:#{@name}}

{{FloatBarrier}}

EOT
    
    generate_diagram(f)
    generate_documentation(f)

    if @type == 'uml:DataType' or @type == 'uml:PrimitiveType'
      generate_data_type(f)
    else
      generate_class(f)
    end

    f.puts "\n{{FloatBarrier}}"

    # generate_class_diagram    
  end
end
