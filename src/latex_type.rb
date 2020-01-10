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
    "./#{LatexModel.directory}/#{png_diagram_name}"
  end

  def tex_diagram_file_name
    "./#{LatexModel.directory}/#{tex_diagram_name}"
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

      f.puts "\n\\input #{tex_diagram_name}\n\n"
    elsif png_diagram_exists?
      # puts "** Generating png diagrams #{png_diagram_file_name}"
      
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
    "./#{LatexModel.directory}/#{documentation_name}"
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

  @@labels = Set.new

  ROW_FORMAT = "|X[-1.35]|X[-0.7]|X[-1.75]|X[-1.5]|X[-1]|X[-0.7]|"

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
      f.puts "\\multicolumn{6}{|l|}{Subtype of #{parent.name} (#{ref})} \\\\"
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
          
          array = '[]' if r.is_array?
          
          if r.is_property? or r.is_folder?
            type_info = "#{hyphenate(r.final_target.type.name)}#{array} & #{hyphenate(r.target_node_name)}"
          elsif r.target.type.is_variable?
            type_info = "#{hyphenate(r.target.type.variable_data_type.name)}#{array} & #{hyphenate(r.target_node_name)}"
          else
            type_info = "\\multicolumn{2}{l|}{#{r.target_node_name}#{array}}"
          end

          f.puts "#{hyphenate(r.reference_type)} & #{r.target.type.base_type} & #{hyphenate(r.browse_name)} & #{type_info} & #{r.rule} \\\\"
        rescue
          $logger.error "#{$!}: #{@name}::#{r.name} #{r.final_target.name} #{r.final_target.type_id} #{r.final_target.type}"
          raise 
        end
      end
    end
  end

  def generate_constraints(f, obj = self)
    unless obj.constraints.empty?
      f.puts "\\paragraph{Constraints}\n"
      obj.constraints.each do |c|
        f.puts "\\begin{itemize}"
        f.puts "\\item Constraint \\texttt{#{c.name}}: "
        f.puts "   \\indent \\begin{lstlisting}"
        f.puts c.specification
        f.puts "\\end{lstlisting}"
        f.puts "Documentation: #{c.documentation}" if c.documentation
        f.puts "\n\\end{itemize}"
      end
    end

    unless obj.invariants.empty?
      f.puts "\n\\paragraph{Static values for #{obj.name}}\n"

      f.puts <<EOT
\\begin{table}[ht]
\\centering 
  \\caption{\\texttt{#{escape_name}::#{obj.name}} Values}
\\tabulinesep=3pt
\\begin{tabu} to 6in {|l|l|} \\everyrow{\\hline}
\\hline
\\rowfont\\bfseries {Name} & {Value} \\\\
\\tabucline[1.5pt]{}
EOT

      obj.invariants.each do |name, value|
        f.puts "\\texttt{#{name}} & \\texttt{#{value}} \\\\"
      end
      
      f.puts <<EOT
\\end{tabu}
\\end{table} 
EOT

      
      f.puts "\\begin{itemize}"
      obj.invariants.each do |k, v|
        f.puts "\\item Property \\texttt{#{k}}: \\texttt{#{v}}"
      end
      f.puts "\\end{itemize}"
    end

    if obj.equal?(self)
      @relations.each do |r|
        generate_constraints(f, r)
      end
    end
  end

  def generate_subtype(f, c)
    t = c.is_a_type?('BaseVariableType') ? 'VariableType' : 'ObjectType'
    f.puts "HasSubtype & #{t} & \\multicolumn{2}{l}{#{c.escape_name}} & \\multicolumn{2}{|l|}{#{c.reference}} \\\\"
  end

  def generate_children(f)
    cs = @children.dup.select { |t| t.model.name !~ /Example/ }
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
\\begin{tabu} to 6in {#{ROW_FORMAT}} \\everyrow{\\hline}
\\hline
\\rowfont \\bfseries References & NodeClass & BrowseName & DataType & Type\\-Definition & {Modeling\\-Rule} \\\\
EOT
      l = cs.pop(22)
      l.each do |c|
        generate_subtype(f, c)
      end
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
      f.puts "\\FloatBarrier"
      f.puts "\\paragraph{#{header}}\n\n"
      f.puts "\\begin{itemize}"
      relations_with_documentation.each do |r|
        if r.documentation
          f.puts "\\item \\texttt{#{r.name} : #{r.final_target.type.name}:} #{r.documentation}\n\n"
        end
        
        if r.target.type.type == 'uml:Enumeration'
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
      @operations.each do |name, docs|
        f.print "  \\item \\texttt{#{name}("
        f.print ")}"
        if false
          f.puts "\\\\\n    Specification:"
          f.puts "   \\indent \\begin{lstlisting}"
          f.puts specs
          f.puts "\\end{lstlisting}"          
        end
        if docs
          f.puts "\\newline    Documentation: #{docs}"
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
\\begin{tabu} to 6in {#{ROW_FORMAT}} \\everyrow{\\hline}
\\hline
\\rowfont\\bfseries {Attribute} & \\multicolumn{5}{|l|}{Value} \\\\
\\tabucline[1.5pt]{}
BrowseName & \\multicolumn{5}{|l|}{#{@name}} \\\\
IsAbstract & \\multicolumn{5}{|l|}{#{@abstract.to_s.capitalize}} \\\\
EOT

    if is_variable?
      v = get_attribute_like('ValueRank')
      f.puts "ValueRank & \\multicolumn{5}{|l|}{#{v.default}} \\\\"
      a = get_attribute_like('DataType') || 'BaseVariableType'
      f.puts "DataType & \\multicolumn{5}{|l|}{#{a.target.type.name}} \\\\"
    elsif is_reference?
      a = get_attribute_like('Symmetric')
      t = a.default || 'false'
      f.puts "Symmetric & \\multicolumn{5}{|l|}{#{t}} \\\\"
    end

    f.puts <<EOT
\\tabucline[1.5pt]{}
\\rowfont \\bfseries References & NodeClass & BrowseName & DataType & Type\\-Definition & {Modeling\\-Rule} \\\\
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
    if @type == 'uml:Enumeration'
      $logger.debug "***** =====> Generating Enumerations for #{@name}"
      
      generate_documentation(f)

      f.puts <<EOT
\\begin{table}[ht]
\\centering 
  \\caption{\\texttt{#{escape_name}} Enumeration}
EOT
      unless @@labels.include?(@name)
        f.puts "  \\label{enum:#{@name}}"
        @@labels.add(@name)
      end

      f.puts <<EOT
\\tabulinesep=3pt
\\begin{tabu} to 6in {|l|r|X|} \\everyrow{\\hline}
\\hline
\\rowfont\\bfseries {Name} & {Index} & {Description} \\\\
\\tabucline[1.5pt]{}
EOT
      
      @literals.each do |lit|
        f.puts "\\texttt{#{lit.name}} & \\texttt{#{lit.value}} & #{lit.description} \\\\"
      end
        
      f.puts <<EOT
\\end{tabu}
\\end{table} 
EOT
    end
  end

  def generate_dependencies(f)

    deps = dependencies.select { |d|
      d.target.type.stereotype.nil? or not (d.target.type.stereotype =~ /Factory/)
    }

    if !deps.empty? or @mixin
      f.puts "\\paragraph{Dependencies and Relationships}"

      f.puts "\n\\begin{itemize}"
      
      deps.each do |dep|
        target = dep.target
        
        if dep.stereotype and dep.stereotype == 'values' and
            target.type.type == 'uml:Enumeration'
          
          f.puts "\\item \\textbf{Allowable Values} for \\texttt{#{target.type.name}}"
          f.puts "\\FloatBarrier"
          target.type.generate_enumerations(f)
          f.puts "\\FloatBarrier"
        else
          f.puts "\\item Dependency on #{target.type.name}\n\n"
          rel = dep.stereotype && dep.stereotype
          if rel
            f.puts "This class relates to \\texttt{#{target.type.name}} (#{target.type.reference}) for a(n) \\texttt{#{rel}} relationship.\n\n"
          else
            $logger.error "Cannot find stereo for #{@name}::#{dep.name} to #{target.type.name}"
          end
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
\\begin{tabu} to 6in {|l|l|l|} \\everyrow{\\hline}
\\hline
\\rowfont\\bfseries {Field} & {Type} & {Optional} \\\\
\\tabucline[1.5pt]{}
EOT

      @relations.each do |r|
        array = '[]' if r.is_array?
        optional = r.is_optional? ? 'Optional' : 'Mandatory'
        f.puts "\\texttt{#{r.name}} & \\texttt{#{r.target.type.name}#{array}} & \\texttt{#{optional}} \\\\"
      end
        
      f.puts <<EOT
\\end{tabu}
\\end{table} 

EOT

      generate_attribute_docs(f, "Data Type Fields")
  end

  def generate_class_diagram
    File.open("./#{LatexModel.directory}/classes/#{@name.gsub(/[<>]/, '-')}.tex", 'w') do |f|
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
     
  def generate_latex(f = STDOUT)
    # puts "--- Generating #{@name} #{@stereotype}"
    return if @name =~ /Factory/ or @stereotype =~ /metaclass/

    f.puts <<EOT
\\subsubsection{Defintion of \\texttt{#{stereotype_name} #{escape_name}}}
  \\label{type:#{@name}}

\\FloatBarrier
EOT
    
    generate_diagram(f)
    generate_documentation(f)

    if @type == 'uml:DataType' or @type == 'uml:PrimitiveType'
      generate_data_type(f)
    else
      generate_class(f)
    end

    f.puts "\\FloatBarrier"

    # generate_class_diagram    
  end
end
