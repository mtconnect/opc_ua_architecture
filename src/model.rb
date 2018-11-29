require 'type'

class Model
  attr_reader :name, :documentation

  @@models = {}

  def self.type_class
    raise "Must use subtype"
  end

  def self.models
    @@models
  end

  def initialize(e)
    @name = e['name']
    @documentation = e['documentation']
    @type = e['_type']
    @json = e
    @types = []
    @is_opc = @name =~ /OPC/
    
    @@models[@name] = self
  end

  def add_type(t)
    @types << t
    @types.sort_by! { |t| t.name }
  end

  def short_name
    @name.gsub(/[ _]/, '')
  end

  def is_opc?
    @is_opc
  end

  def to_s
    @name
  end

  def self.recurse(e, depth, model)
    return if SkipModels.include?(e['name'])
    
    if e.include?('ownedElements')
      e['ownedElements'].each do |f|      
        find_definitions(f, depth, model)
      end
    end
  end
  
  def self.find_definitions(e, depth = 0, model = nil)
    # puts "#{'  ' * depth}#{model}::#{e['name']} #{e['_type']}"
    
    case e['_type']
    when 'UMLClass'
      type_class.new(model, e)

    when 'UMLObject'
      type_class.new(model, e)
      
    when 'UMLStereotype'
      type_class.new(model, e)
      
    when 'UMLDataType', 'UMLEnumeration', 'UMLPrimitiveType'
      #   puts "#{'  ' * depth}  Adding data type: #{e['name']}  id: #{e['_id']}"
      type_class.new(model, e)
      
    when 'UMLModel', 'UMLProfile'
      model = self.new(e)
      recurse(e, depth + 1, model)

    else
      recurse(e, depth + 1, model)
    end
  end
  
end

