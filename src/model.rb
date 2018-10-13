require 'type'

class Model
  attr_reader :name, :documentation

  @@models = {}

  def self.models
    @@models
  end

  def initialize(e)
    @name = e['name']
    @documentation = e['documentation']
    @type = e['_type']
    @json = e
    @types = []
    
    @@models[@name] = self
  end

  def add_type(t)
    @types << t
    @types.sort_by! { |t| t.name }
  end

  def short_name
    @name.gsub(/[ _]/, '')
  end

  def to_s
    @name
  end

  def self.recurse(e, depth, model)
    if e.include?('ownedElements')
      e['ownedElements'].each do |f|      
        find_definitions(f, depth, model)
      end
    end
  end
  
  def self.find_definitions(e, depth = 0, model = nil)
    puts "#{'  ' * depth}#{model}::#{e['name']} #{e['_type']}"
    
    case e['_type']
    when 'UMLClass'
      Type.new(model, e)
      
    when 'UMLStereotype'
      Type.new(model, e)
      
    when 'UMLDataType', 'UMLEnumeration'
      #   puts "#{'  ' * depth}  Adding data type: #{e['name']}  id: #{e['_id']}"
      Type.new(model, e)
      
    when 'UMLModel', 'UMLProfile'
      model = Model.new(e)
      recurse(e, depth + 1, model)
      
    else
      recurse(e, depth + 1, model)
    end
  end
  
end

