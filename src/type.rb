

class Type
  attr_reader :name, :id, :type, :model
  
  @@types = {}

  def self.types
    @@types
  end

  def self.types_by_model
    models = Hash.new
    @@types.each do |id, type|
      model = type.model.name || 'Stereotype'
      puts "#{model}::#{type.name}"
      a = (models[model] ||= [])
      a << type
    end
    models.each do |model, types|
      types.sort_by! { |t| t.name }
    end
    models
  end

  def self.connect_children
    @@types.each do |id, type|
      parent = type.get_parent
      parent.add_child(type) if parent
    end
  end
  
  def initialize(model, e)
    @name = e['name']
    @id = e['_id']
    @type = e['_type']
    @documentation = e['documentation']
    @attributes = e['attributes']
    @relations = e['ownedElements']
    @operations = e['operations']
    @abstract = e['isAbstract'] || false
    @model = model

    if e['stereotype']
      @stereotype = resolve_type(e['stereotype'])
    end

    

    @children = []

    @json = e

    @@types[@id] = self

    @model.add_type(self)
  end

  def escape_name
    @name.gsub('{', '\{').gsub('}', '\}')
  end

  def add_child(c)
    @children << c
  end

  def stereotype_name
    if @stereotype
      "<<#{@stereotype.name}>>"
    else
      ''
    end
  end

  def to_s
    "#{@model}::#{@name} -> #{stereotype_name} #{@type}"
  end

  def resolve_type(ref)
    id = ref['$ref'] if ref
    type = @@types[id] if id
  end

  def resolve_type_name(prop)
    if String === prop
      prop
    else
      type = resolve_type(prop)
      if type
        type.name
      else
        'Unknown'
      end
    end
  end

  def get_parent
    if @relations
      @relations.each do |rel|
        if rel['_type'] == 'UMLGeneralization'
          parent_id = rel['target']['$ref']
          parent = @@types[parent_id]
          return parent
        end
      end        
    end
    nil
  end
  
  def generate_supertype(f)
    parent = get_parent
    if parent
      if parent.model != @model
        ref = "See #{parent.model} Documentation"
      else
        ref = "see section \\ref{type:#{parent.name}}"
      end
      f.puts "\\multicolumn{6}{|l|}{Subtype of #{parent.name} (#{ref})} \\\\"
    end
  end

  def mandatory(obj)
    if obj['multiplicity'] == '0..1'
      'Optional'
    else
      'Mandatory'
    end
  end

  def generate_properties(f)
    if @attributes
      @attributes.each do |a|
        type = resolve_type_name(a['type'])
        # puts "#{a['name']} -> #{type}"
        f.puts "HasProperty & Variable & #{a['name']} &  #{type} & PropertyType & #{mandatory(a)} \\\\"
      end
    end
  end

  def generate_constraints(f)
    if @relations
      constraints = @relations.select do |r|
        r['_type'] == 'UMLConstraint'
      end

      unless constraints.empty?
        f.puts "\\paragraph{Constraints}\n"
        constraints.each do |c|
          f.puts "\\begin{itemize}"
          f.puts "\\item Constraint \\texttt{#{c['name']}}: "
          f.puts "   \\indent \\begin{Verbatim}[xleftmargin=.25in,fontsize=\\small]"
          f.puts c['specification']
          f.puts "\\end{Verbatim}"
          f.puts "Documentation: #{c['documentation']}" if c.include?('documentation')
          f.puts "\n\\end{itemize}"
        end
      end
    end
  end

  def generate_relations(f)
    if @relations
      @relations.each do |r|
        if r['_type'] == 'UMLAssociation'
          optional = mandatory(r['end1'])
          target = resolve_type(r['end2']['reference'])
          stereo = resolve_type(r['stereotype'])
          node = 'Object'
          browse = r['name']

          if r['name'].nil?
            relation = 'HasProperty'
            type_name = target.name
            type_def = '<Dynamic>'
            browse = '<Dynamic>'
            node = 'Variable'
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
  end

  def generate_children(f)
  end

  def generate_operations(f)
    if @operations
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
          f.puts "   \\indent \\begin{Verbatim}[xleftmargin=.25in,fontsize=\\small]"
          f.puts op['specification']
          f.puts "\\end{Verbatim}"
        end
        if op['documentation']
          f.puts "\\\\\n    Documentation: #{op['documentation']}"
        end
        f.puts
      end
      f.puts "\\end{itemize}"
    end
  end

  def generate_type_table(f)
    f.puts <<EOT
\\begin{table}
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
\\tabucline[1.5pt]{}
\\rowfont \\bfseries References & NodeClass & BrowseName & DataType & TypeDefinition & {Modeling Rule} \\\\
EOT

    generate_supertype(f)
    generate_properties(f)
    generate_relations(f)
    generate_children(f)

    f.puts <<EOT
\\end{tabu}
\\end{table} 

\\FloatBarrier

EOT
  end
    
  def generate_latex(f = STDOUT)
    f.puts <<EOT
\\subsubsection{Defintion of #{stereotype_name} \\texttt{#{escape_name}}} \\label{type:#{@name}}

\\FloatBarrier

#{@documentation}

EOT

    if stereotype_name !~ /Factory/o and @model.name !~ /Profile/
      generate_type_table(f) 
    end
      
    generate_operations(f)
    generate_constraints(f)
  
  end
end
