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
        ref = "See #{parent.model} Documentation"
      else
        ref = parent.reference
      end
      f.puts "\\multicolumn{6}{|l|}{Subtype of \\texttt{#{parent.name}} (#{ref})} \\\\"
    end
  end

  def mandatory(obj)
    if obj['multiplicity'] == '0..1' or obj['multiplicity'] == '0..*'
      'Optional'
    else
      'Mandatory'
    end
  end

  def generate_properties(f)
    @attributes.each do |a|
      type = resolve_type_name(a['type'])
      stereo = a['stereotype'] && resolve_type_name(a['stereotype'])
      unless stereo =~ /Attribute/
        f.puts "HasProperty & Variable & #{a['name']} &  #{type} & PropertyType & #{mandatory(a)} \\\\"
      end
    end
  end

  def generate_constraints(f)
    constraints = @relations.select do |r|
      r['_type'] == 'UMLConstraint'
    end
    
    unless constraints.empty?
      f.puts "\\paragraph{Constraints}\n"
      constraints.each do |c|
        f.puts "\\begin{itemize}"
        f.puts "\\item Constraint \\texttt{#{c['name']}}: "
        f.puts "   \\indent \\begin{lstlisting}"
        f.puts c['specification']
        f.puts "\\end{lstlisting}"
        f.puts "Documentation: #{c['documentation']}" if c.include?('documentation')
        f.puts "\n\\end{itemize}"
      end
    end
  end

  def generate_relations(f)
    @relations.each do |r|
      if r['_type'] == 'UMLAssociation'
        optional = mandatory(r['end1'])
        target = resolve_type(r['end2']['reference'])
        stereo = resolve_type(r['stereotype'])

        next if stereo and stereo.name =~ /Attribute/
        
        node = 'Object'
        browse = r['name']
        browse = r['end1']['name'] unless browse

        if browse.nil?
          relation = (stereo && stereo.name) || 'HasProperty'
          type_name = target.name
          if relation == 'HasProperty'
            type_def = 'PropertyType'
            node = 'Variable'
          else
            type_def = '<Dynamic>'
            node = 'Object'
          end
          browse = '<Dynamic>'
        elsif r['end2']['multiplicity'] == '1'
          type_name = ''
          relation =  'HasComponent'
          type_def = target.name
        elsif stereo
          relation = stereo.name == 'FolderType' ? 'Organizes' : stereo.name
          type_def = stereo.name
          type_name = target.name
        else
          type_def = target.name
          type_name = ''
          relation = 'HasComponent'
        end
          
        f.puts "#{relation} & #{node} & #{browse} &  #{type_name} & #{type_def} & #{optional} \\\\"          
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
      a = get_attribute_like(/DataType$/)
      t = case a
          when String
            a

          when Hash
            a['type']

          else
            'BaseVariableType'
          end
      f.puts "DataType & \\multicolumn{5}{|l|}{#{t}} \\\\"
    elsif @name =~ /^Has/
      a = get_attribute_like(/Symmetric/)
      t = a['defaultValue'] || 'false'
      f.puts "Symmetric & \\multicolumn{5}{|l|}{#{t}} \\\\"
    end

    f.puts <<EOT
\\tabucline[1.5pt]{}
\\rowfont \\bfseries References & NodeClass & BrowseName & DataType & TypeDefinition & {Modeling Rule} \\\\
EOT

    generate_supertype(f)
    generate_children(f)

    realization_targets.each do |stereo, target|
      if stereo.name == 'Mixes In'
        target.mixin_properties(f)
      end
    end

    generate_properties(f)
    generate_relations(f)

    f.puts <<EOT
\\end{tabu}
\\end{table} 


EOT
  end

  def generate_enumerations(f)
    if @type == 'UMLEnumeration'
      
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
        f.puts "\\texttt{#{name}} & \\texttt{#{value}} \\\\"
      end
        
      f.puts <<EOT
\\end{tabu}
\\end{table} 
EOT
    end
  end

  def generate_dependencies(f)
    if @relations
      dependency_targets.each do |stereo, target|
        if stereo.name == 'values' and target.type == 'UMLEnumeration'
          f.puts "\\paragraph{Allowable Values}"
          target.generate_enumerations(f)
        else
          f.puts "\\paragraph{Dependency on #{target.name}}\n\n"
          f.puts "This class relates to \\texttt{#{target.name}} (#{target.reference}) for a(n) \\texttt{#{stereo.name}} relationship.\n\n"
        end
      end

      realization_targets.each do |stereo, target|
        if stereo.name == 'Mixes In'
          f.puts "\\paragraph{Mixes in \\texttt{#{target.escape_name}}} (#{target.reference})"
        end
      end
    end
  end
    
  def generate_latex(f = STDOUT)
    f.puts <<EOT
\\subsubsection{Defintion of \\texttt{#{stereotype_name} #{escape_name}}} \\label{type:#{@name}}

\\FloatBarrier
EOT
    generate_diagram(f)

    f.puts "\n#{@documentation}\n\n"

    if stereotype_name !~ /Factory/o and (is_a_type?('References') or @model.name !~ /Profile/)
      generate_type_table(f) 
    end
      
    generate_operations(f)
    generate_constraints(f)
    generate_dependencies(f)

    f.puts "\\FloatBarrier"  
  end
end