require 'type'

module Diagram
  def diagram_name
    "./diagrams/#{short_name}.png"
  end

  def diagram_file_name
    "./latex/#{diagram_name}"
  end

  def diagram_exists?
    File.exists?(diagram_file_name)
  end
  
  def generate_diagram(f)
    if diagram_exists?
      puts "** Generating diagrams #{diagram_file_name}"
      
      f.puts <<EOT

\\begin{figure}[ht]
  \\centering
    \\includegraphics[width=1.0\\textwidth]{#{diagram_name}}
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

class Type
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
        if r.is_property?
          type_info = "#{r.target.type.name} & #{r.target_node_name}"
        elsif r.is_folder?
          type_info = "#{r.final_target.type.name} & #{r.target_node_name}"          
        else
          type_info = "\\multicolumn{2}{|l|}{#{r.target_node_name}}"
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
\\tabulinesep=3pt
\\begin{tabu} to 6in {|l|r|} \\everyrow{\\hline}
\\hline
\\rowfont\\bfseries {Name} & {Index} \\\\
\\tabucline[1.5pt]{}
EOT
      
      @json['literals'].each do |lit|
        name, value = lit['name'].split('=')
        f.puts "\\texttt{#{name}_#{value}} & \\texttt{#{value}} \\\\"
      end
        
      f.puts <<EOT
\\end{tabu}
\\end{table} 
EOT
    end
  end

  def generate_dependencies(f)
    dependencies.each do |dep|
      target = dep.target
      if dep.stereotype and dep.stereotype.name == 'values' and
            target.type.type == 'UMLEnumeration'
        
        f.puts "\\paragraph{Allowable Values}"
        target.type.generate_enumerations(f)
      else
        f.puts "\\paragraph{Dependency on #{target.type.name}}\n\n"
        rel = dep.stereotype && dep.stereotype.name
        puts "Cannot find stereo for #{@name}::#{dep.name} to #{target.type.name}" unless rel
        f.puts "This class relates to \\texttt{#{target.type.name}} (#{target.type.reference}) for a(n) \\texttt{#{rel}} relationship.\n\n"
      end
    end
    
    f.puts "\\paragraph{Mixes in \\texttt{#{@mixin.escape_name}}} (#{@mixin.reference})" if @mixin
  end

  def generate_data_type(f)
      f.puts <<EOT
\\begin{table}[ht]
\\centering 
  \\caption{\\texttt{#{escape_name}} DataType}
  \\label{table:#{@name}}
\\tabulinesep=3pt
\\begin{tabu} to 6in {|l|r|} \\everyrow{\\hline}
\\hline
\\rowfont\\bfseries {Field} & {Type} \\\\
\\tabucline[1.5pt]{}
EOT

      @relations.each do |r|
        f.puts "\\texttt{#{r.name}} & \\texttt{#{r.target.type.name}} \\\\"
      end
        
      f.puts <<EOT
\\end{tabu}
\\end{table} 
EOT
  end

  def generate_class(f)
    if stereotype_name !~ /Factory/o and (is_a_type?('References') or @model.name !~ /Profile/)
      generate_type_table(f) 
    end
    
    generate_operations(f)
    generate_constraints(f)
    generate_dependencies(f)    
  end
     
  def generate_latex(f = STDOUT)
    f.puts <<EOT
\\subsubsection{Defintion of \\texttt{#{stereotype_name} #{escape_name}}} \\label{type:#{@name}}

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
  end
end
