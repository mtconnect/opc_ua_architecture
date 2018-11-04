require 'type'

module Diagram
  def png_diagram_name
    "./diagrams/types/#{short_name}.png"
  end

  def tex_diagram_name
    "./diagrams/types/#{short_name}.tex"
  end

  def png_diagram_file_name
    "./latex/#{png_diagram_name}"
  end

  def tex_diagram_file_name
    "./latex/#{tex_diagram_name}"
  end

  def png_diagram_exists?
    File.exists?(png_diagram_file_name)      
  end

  def tex_diagram_exists?
    File.exists?(tex_diagram_file_name)
  end
  
  def generate_diagram(f)
    if tex_diagram_exists?
      puts "** Generating png diagrams #{tex_diagram_file_name}"

      f.puts "\n\\input #{tex_diagram_name}\n\n"
    elsif png_diagram_exists?
      puts "** Generating png diagrams #{png_diagram_file_name}"
      
      f.puts <<EOT

\\begin{figure}[ht]
  \\centering
    \\includegraphics[width=1.0\\textwidth]{#{png_diagram_name}}
  \\caption{#{@name} Diagram}
  \\label{fig:#{short_name}}
\\end{figure}

\\FloatBarrier

EOT
    end
  end
end

module Document
  def documentation_name
    "./type-sections/#{short_name}.tex"
  end

  def documentation_file_name
    "./latex/#{documentation_name}"
  end


  def documentation_exists?
    File.exists?(documentation_file_name)
  end

  def generate_documentation(f)
    if documentation_exists?
      f.puts "\n\\input #{documentation_name}\n\n"
    elsif @documentation
      f.puts "\n#{@documentation}\n\n"
    end
  end
end

class LatexType < Type
  include Diagram
  include Document

  def reference
    "See section \\ref{type:#{@name}}"
  end
  
  def generate_supertype(f)
    parent = get_parent
    if parent
      if parent.model != @model
        ref = "See #{parent.model.reference} Documentation"
      else
        ref = parent.reference
      end
      f.puts "\\multicolumn{6}{|l|}{Subtype of \\texttt{#{parent.name}} (#{ref})} \\\\"
    end
  end

  def mixin_relations(f)
    @parent.mixin_relations(f) if @parent
    generate_relations(f)
  end

  def generate_relations(f)
    @relations.each do |r|
      if r.is_reference?
        next if r.stereotype and r.stereotype.name =~ /Attribute/

        array = '[]' if r.is_array?
        
        if r.is_property? or r.is_folder?
          type_info = "#{r.final_target.type.name}#{array} & #{r.target_node_name}"
        else
          type_info = "\\multicolumn{2}{|l|}{#{r.target_node_name}#{array}}"
        end

        f.puts "#{r.reference_type} & #{r.target.type.base_type} & #{r.browse_name} & #{type_info} & #{r.rule} \\\\"          
      end
    end
  end

  def generate_constraints(f)
    unless @constraints.empty?
      f.puts "\\paragraph{Constraints}\n"
      @constraints.each do |c|
        f.puts "\\begin{itemize}"
        f.puts "\\item Constraint \\texttt{#{c.name}}: "
        f.puts "   \\indent \\begin{lstlisting}"
        f.puts c.specification
        f.puts "\\end{lstlisting}"
        f.puts "Documentation: #{c.documentation}" if c.documentation
        f.puts "\n\\end{itemize}"
      end
    end
  end

  def generate_subtype(f, c)
    t = c.is_a_type?('BaseVariableType') ? 'VariableType' : 'ObjectType'
    f.puts "HasSubtype & #{t} & #{c.escape_name} & \\multicolumn{3}{|l|}{#{c.reference}} \\\\"
  end

  def generate_children(f)
    cs = @children.dup
    l = cs.pop(22)
    l.each do |c|
      generate_subtype(f, c)
    end
    
    while !cs.empty?
      f.puts <<EOT
\\multicolumn{6}{|l|}{Continued...} \\\\
\\end{tabu}
\\end{table}
\\begin{table}[ht]
\\fontsize{9pt}{11pt}\\selectfont
\\tabulinesep=3pt
\\begin{tabu} to 6in {|l|l|l|l|l|l|} \\everyrow{\\hline}
\\hline
\\rowfont \\bfseries References & NodeClass & BrowseName & DataType & TypeDefinition & {Modeling Rule} \\\\
EOT
      l = cs.pop(22)
      l.each do |c|
        generate_subtype(f, c)
      end
    end
  end

  def generate_attribute_docs(f, header)
    relations_with_documentation =
      @relations.select { |r| r.documentation or r.target.type.type == 'UMLEnumeration' }

    unless relations_with_documentation.empty?
      f.puts "\\FloatBarrier"
      f.puts "\\paragraph{#{header}}\n\n"
      f.puts "\\begin{itemize}"
      relations_with_documentation.each do |r|
        if r.documentation
          f.puts "\\item \\texttt{#{r.name}::#{r.final_target.type.name}:} #{r.documentation}\n\n"
        end
        
        if r.target.type.type == 'UMLEnumeration'
          f.puts "\\item \\textbf{Allowable Values} for \\texttt{#{r.target.type.name}}"
          f.puts "\\FloatBarrier"
          r.target.type.generate_enumerations(f)
          f.puts "\\FloatBarrier"
        end
      end
      f.puts "\\end{itemize}"
    end

    
  end
  
  def generate_operations(f)
    if !@operations.empty?
      f.puts "\\paragraph{Operations}\n"
      
      f.puts "\\begin{itemize}"
      @operations.each do |op|
        f.print "  \\item \\texttt{#{op['name']}("
        if op['parameters']
          f.print op['parameters'].map { |param|
            ((param['type'] and !param['type'].empty?) ? param['type'] : "") +
              param['name']
          }.join(', ')
        end
        f.print ")}"
        if op['specification']
          f.puts "\\\\\n    Specification:"
          f.puts "   \\indent \\begin{lstlisting}"
          f.puts op['specification']
          f.puts "\\end{lstlisting}"
          
        end
        if op['documentation']
          f.puts "\n    Documentation: #{op['documentation']}"
        end
        f.puts
      end
      f.puts "\\end{itemize}"
    end
  end

  def generate_type_table(f)
    f.puts <<EOT
\\begin{table}[ht]
\\centering 
  \\caption{\\texttt{#{escape_name}} Definition}
  \\label{table:#{@name}}
\\fontsize{9pt}{11pt}\\selectfont
\\tabulinesep=3pt
\\begin{tabu} to 6in {|l|l|l|l|l|l|} \\everyrow{\\hline}
\\hline
\\rowfont\\bfseries {Attribute} & \\multicolumn{5}{|l|}{Value} \\\\
\\tabucline[1.5pt]{}
BrowseName & \\multicolumn{5}{|l|}{#{@name}} \\\\
IsAbstract & \\multicolumn{5}{|l|}{#{@abstract.to_s.capitalize}} \\\\
EOT

    if is_a_type?('BaseVariableType')
      f.puts "ValueRank & \\multicolumn{5}{|l|}{-1} \\\\"
      a = get_attribute_like(/DataType$/) || 'BaseVariableType'
      f.puts "DataType & \\multicolumn{5}{|l|}{#{a.target.type.name}} \\\\"
    elsif is_a_type?('References')
      a = get_attribute_like(/Symmetric/)
      t = a.json['defaultValue'] || 'false'
      f.puts "Symmetric & \\multicolumn{5}{|l|}{#{t}} \\\\"
    end

    f.puts <<EOT
\\tabucline[1.5pt]{}
\\rowfont \\bfseries References & NodeClass & BrowseName & DataType & TypeDefinition & {Modeling Rule} \\\\
EOT

    generate_supertype(f)
    generate_children(f)

    @mixin.mixin_relations(f) if @mixin
    
    generate_relations(f)

    f.puts <<EOT
\\end{tabu}
\\end{table} 


EOT
  end

  def generate_enumerations(f)
    if @type == 'UMLEnumeration'
      puts "***** =====> Generating Enumerations for #{@name}"
      
      generate_documentation(f)

      f.puts <<EOT
\\begin{table}[ht]
\\centering 
  \\caption{\\texttt{#{escape_name}} Enumeration}
  \\label{enum:#{@name}}
\\tabulinesep=3pt
\\begin{tabu} to 6in {|l|r|} \\everyrow{\\hline}
\\hline
\\rowfont\\bfseries {Name} & {Index} \\\\
\\tabucline[1.5pt]{}
EOT
      
      @json['literals'].each do |lit|
        name, value = lit['name'].split('=')
        f.puts "\\texttt{#{name}} & \\texttt{#{value}} \\\\"
      end
        
      f.puts <<EOT
\\end{tabu}
\\end{table} 
EOT
    end
  end

  def generate_dependencies(f)

    deps = dependencies.select { |d|
      d.target.type.stereotype.nil? or d.target.type.stereotype.name !~ /Factory/
    }

    if !deps.empty? or @mixin
      f.puts "\\paragraph{Dependencies and Relationships}"
      
      deps.each do |dep|
        target = dep.target
        
        if dep.stereotype and dep.stereotype.name == 'values' and
            target.type.type == 'UMLEnumeration'
          
          f.puts "\\item \\textbf{Allowable Values} for \\texttt{#{target.type.name}}"
          f.puts "\\FloatBarrier"
          target.type.generate_enumerations(f)
          f.puts "\\FloatBarrier"
        else
          f.puts "\\item Dependency on #{target.type.name}\n\n"
          rel = dep.stereotype && dep.stereotype.name
          puts "Cannot find stereo for #{@name}::#{dep.name} to #{target.type.name}" unless rel
          f.puts "This class relates to \\texttt{#{target.type.name}} (#{target.type.reference}) for a(n) \\texttt{#{rel}} relationship.\n\n"
        end
      end
    
      f.puts "\\item Mixes in \\texttt{#{@mixin.escape_name}}, see #{@mixin.reference}" if @mixin
      f.puts "\\end{itemize}"
    end
  end

  def generate_data_type(f)
      f.puts <<EOT
\\begin{table}[ht]
\\centering 
  \\caption{\\texttt{#{escape_name}} DataType}
  \\label{data-type:#{@name}}
\\tabulinesep=3pt
\\begin{tabu} to 6in {|l|l|} \\everyrow{\\hline}
\\hline
\\rowfont\\bfseries {Field} & {Type}  \\\\
\\tabucline[1.5pt]{}
EOT

      @relations.each do |r|
        array = '[]' if r.multiplicity =~ /..\*$/
        f.puts "\\texttt{#{r.name}} & \\texttt{#{r.target.type.name}#{array}} \\\\"
      end
        
      f.puts <<EOT
\\end{tabu}
\\end{table} 

EOT

      generate_attribute_docs(f, "Data Type Fields")
  end

  def generate_class_diagram
    File.open("latex/classes/#{@name.gsub(/[<>]/, '-')}.tex", 'w') do |f|
      if @abstract
        f.puts "\\umlabstract{#{@name}}{"
      else
        f.puts "\\umlclass{#{@name}}{"
      end

      @relations.each do |r|
        if r.is_property?
          if r.stereotype
            stereo = "<<#{r.stereotype.name}>> "
          end
          f.puts "#{stereo}+ #{r.name}: #{r.target.type.name}#{r.is_optional? ? '[0..1]' : ''} \\\\"
        end
      end
      
      f.puts "}{}"
      f.puts "\n% Relationships\n\n"
      
      @relations.each do |r|
        if !r.is_property?
          if r.stereotype
            stereo = "stereo=#{r.stereotype.name},"
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
     
  def generate_latex(f = STDOUT)
    f.puts <<EOT
\\subsubsection{Defintion of \\texttt{#{stereotype_name} #{escape_name}}}
  \\label{type:#{@name}}

\\FloatBarrier
EOT
    
    generate_diagram(f)
    generate_documentation(f)

    if @type == 'UMLDataType'
      generate_data_type(f)
    else
      generate_class(f)
    end

    f.puts "\\FloatBarrier"

    generate_class_diagram    
  end
end
