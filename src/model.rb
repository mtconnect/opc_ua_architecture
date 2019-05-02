require 'type'

class Model
  attr_reader :name, :documentation, :types

  @@skip_models = {}
  @@models = {}

  def self.clear
    @@models.clear
    @@skip_models.clear
  end
  
  def self.type_class
    raise "Must use subtype"
  end

  def self.skip_models=(models)
    @@skip_models = models
  end

  def self.models
    @@models
  end

  def self.clear
    @@models.clear
  end

  def initialize(e)
    @name = e['name']
    @documentation = e['documentation']
    @type = e['type']
    @json = e
    @types = []
    @is_opc = !((@name =~ /OPC/).nil?)
    
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

  def self.find_elements(doc)
    doc.xpath('//elements/element').each do |e|
      Type.add_element(e)
    end
    doc.xpath('//connectors/connector').each do |e|
      Relation.add_connection(e)
    end
  end

  def self.recurse(e, depth, model)
    return if @@skip_models.include?(e['name'])

    e.packagedElement.each do |e|
      find_definitions(e, depth, model)
    end
  end

  def self.find_definitions(e, depth = 0, model = nil)
#    e.each_element('./packagedElement[@type="uml:Class" or @type="uml:Object" or @type="uml:Stereotype"') do |e|
#      type_class.new(model, e)
#    end    
    
    # puts "#{'  ' * depth}#{model}::#{e['name']} #{e['type']}"
    
    case e['type']
    when 'uml:Class'
      type_class.new(model, e)

    when 'uml:Object'
      type_class.new(model, e)
      
    when 'uml:Stereotype'
      type_class.new(model, e)
      
    when 'uml:DataType', 'uml:Enumeration', 'uml:PrimitiveType'
      #   puts "#{'  ' * depth}  Adding data type: #{e['name']}  id: #{e['_id']}"
      type_class.new(model, e)
      
    when 'uml:Package', 'uml:Profile'
      model = self.new(e)
      recurse(e, depth + 1, model)

    when 'uml:Association'
    # assoc = Association.new(nil, e)

    when 'uml:Realization'
      
    when 'uml:Dependency'
      
    else
      puts "Unknown type #{e['type']}}"
    end
  end
  
end

