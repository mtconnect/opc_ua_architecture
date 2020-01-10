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
    @id = e['xmi:id']
    @name = e['name']
    @type = e['xmi:type']
    @xmi = e
    @types = []
    @is_opc = !((@name =~ /OPC/).nil?)

    comment = e.at('./ownedComment')
    @documentation = comment['body'].gsub(/<[\/]?[a-z]+>/, '') if comment
    
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
    $logger.info "#{'  ' * depth}Finding classes for '#{@name}' '#{@type}'"

    @xmi.xpath('./packagedElement[@xmi:type="uml:DataType" or @xmi:type="uml:Enumeration" or @xmi:type="uml:PrimitiveType"]').each do |e|
      $logger.debug "#{'  ' * depth}#{@name}::#{e['name']} #{e['xmi:type']}"
      self.class.type_class.new(self, e)
    end    

    @xmi.xpath('./packagedElement[@xmi:type="uml:Class" or @xmi:type="uml:Object" or @xmi:type="uml:Stereotype" or @xmi:type="uml:AssociationClass" or @xmi:type="uml:InstanceSpecification"]', $namespaces).each do |e|
      $logger.debug "#{'  ' * depth}#{@name}::#{e['name']} #{e['xmi:type']}"
      self.class.type_class.new(self, e)
    end

    @xmi.xpath('./packagedElement[@xmi:type="uml:Package" or @xmi:type="uml:Profile"]').each do |e|
      unless @@skip_models.include?(e['name'])
        $logger.debug "Recursing model: #{e['name']}"
        model = self.class.new(e)
        model.find_definitions(depth + 1)
      else
        $logger.info "Skipping model #{e['name']}"
      end
    end

    $logger.debug "Getting associations for #{@name}"
    @xmi.xpath('./packagedElement[@xmi:type="uml:Realization" or @xmi:type="uml:Dependency" or @xmi:type="uml:Association" or @xmi:type="uml:InformationFlow"]').each do |e|
      self.class.type_class.add_free_association(e)
    end

    if depth == 0
      Type.connect_model
    end
  end
  
end

