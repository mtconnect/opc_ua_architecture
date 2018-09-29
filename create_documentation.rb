require 'json'

uml = File.open('MTConnect OPC-UA Devices.mdj').read
doc = JSON.parse(uml)

models = doc['ownedElements'].select { |e| e['name'] != 'UMLStandardProfile' }

class Model
  attr_reader :name, :documentation

  @@models = {}

  def self.models
    @@models
  end

  def initialize(e)
    @name = e['name'].gsub('{', '\{').gsub('}'. '\}')
    @documentation = e['documentation']
    @type = e['_type']
    @json = e

    @@models[@name] = self
  end

  def to_s
    @name
  end
end

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

  def generate_properties(f)
    if @attributes
      @attributes.each do |a|
        type = resolve_type_name(a['type'])
        # puts "#{a['name']} -> #{type}"
        f.puts "HasProperty & Variable & #{a['name']} &  #{type} & PropertyType & #{a['multiplicity'] == '0..1' ? 'Optional' : 'Manditory'} \\\\"
      end
    end
  end

  def generate_relations(f)
    if @relations
      @relations.each do |r|
        if r['_type'] == 'UMLAssociation'
          optional = r['end1']['multiplicity'] == '0..1' ? 'Optional' : 'Manditory'
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
          f.puts "\\\\\n    Specification: \\texttt{#{op['specification']}}"
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
  \\caption{\\texttt{#{@name}} Definition}
  \\label{table:#{@name}}
\\footnotesize
\\tabulinesep=3pt
\\begin{tabu} to 6in {|X[1.3]|X[1]|X[1.6]|X[2]|X[1.5]|X[1]|} \\everyrow{\\hline}
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
\\subsubsection{Defintion of \\texttt{#{@name}}} \\label{type:#{@name}}

\\FloatBarrier

#{@documentation}

EOT

    if stereotype_name !~ /Factory/o and @model.name !~ /Profile/
      generate_type_table(f) 
    end
      
    generate_operations(f)
  
  end
end

def recurse(e, depth, model)
  if e.include?('ownedElements')
    e['ownedElements'].each do |f|      
      find_definitions(f, depth + 1, model)
    end
  end
end

def find_definitions(e, depth = 0, model = nil)
#  puts "#{'  ' * depth}#{model}::#{e['name']} #{e['_type']}"

  case e['_type']
  when 'UMLClass'
    Type.new(model, e)

  when 'UMLStereotype'
    Type.new(model, e)

  when 'UMLDataType', 'UMLEnumeration'
#   puts "#{'  ' * depth}  Adding data type: #{e['name']}  id: #{e['_id']}"
    Type.new(model, e)

  when 'UMLModel', 'UMLProfile'
#   puts "#{'  ' * depth}Model #{e['name']} - #{e['documentation']}"
    model = Model.new(e)
    recurse(e, depth, model)
    
  else
    recurse(e, depth, model)
  end
end

models.each do |e|
  find_definitions(e)
end

Type.connect_children

Type.types_by_model

puts "\nGenerating LaTex"

def generate_section(f, models, name)
  f.puts "\\subsection{#{name}}"

  f.puts <<EOT

\\begin{figure}
  \\centering
    \\includegraphics[width=1.0\\textwidth]{diagrams/#{name}.png}
  \\caption{#{name} Diagram}
  \\label{fig:#{name}}
\\end{figure}

\\FloatBarrier

EOT
  
  model = Model.models[name]
  f.puts "\n#{model.documentation}\n\n"
  
  models[name].each do |type|
    if type.type == 'UMLClass' or type.type == 'UMLStereotype'
      puts type
      type.generate_latex(f) 
    end
  end
end

File.open('./latex/types.tex', 'w') do |f|
  models = Type.types_by_model

  generate_section(f, models, 'Components')
  generate_section(f, models, 'Data Items')
  generate_section(f, models, 'Conditions')
  generate_section(f, models, 'Factories')
  generate_section(f, models, 'MTConnect Device Profile')
  
end
