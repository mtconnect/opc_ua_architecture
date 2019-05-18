require 'type'

class Model
  include Extensions
  
  attr_reader :name, :documentation, :types, :xmi

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
    @id = e['id']
    @name = e['name']
    @type = e['type']
    @xmi = e
    @types = []
    @is_opc = !((@name =~ /OPC/).nil?)

    @extended = e.at("//element[@idref='#{@id}']")
    unpack_extended_properties(@extended)
    
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

  def find_definitions(depth = 0)
    #puts "#{'  ' * depth}Finding classes for '#{@name}'"
    @xmi.xpath('./packagedElement[@type="uml:DataType" or @type="uml:Enumeration" or @type="uml:PrimitiveType"]').each do |e|
      #puts "#{'  ' * depth}#{@name}::#{e['name']} #{e['type']}"
      self.class.type_class.new(self, e)
    end    

    @xmi.xpath('./packagedElement[@type="uml:Class" or @type="uml:Object" or @type="uml:Stereotype" or @type="uml:AssociationClass" or @type="uml:InstanceSpecification"]').each do |e|
      # puts "#{'  ' * depth}#{@name}::#{e['name']} #{e['type']}"
      self.class.type_class.new(self, e)
    end

    @xmi.xpath('./packagedElement[@type="uml:Package" or @type="uml:Profile"]').each do |e|
      unless @@skip_models.include?(e['name'])
        # puts "Recursing model: #{e['name']}"
        model = self.class.new(e)
        model.find_definitions(depth + 1)
      else
        # puts "Skipping model #{e['name']}"
      end
    end

    if (depth == 0)
      # Grab free associations
      self.class.models.each do |k, v|
        # puts "Getting associations for #{v}"
        v.xmi.xpath('./packagedElement[@type="uml:Association" or @type="uml:Realization" or @type="uml:Dependency"]').each do |e|
          self.class.type_class.add_free_association(e)
        end
      end
      Type.connect_model
    end

  end
  
end

