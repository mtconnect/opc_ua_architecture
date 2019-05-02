require 'relation'
require 'extensions'

class Type
  include Extensions
  
  attr_reader :name, :id, :type, :model, :json, :parent, :children, :relations, :stereotype,
              :tags, :extended, :documentation
  attr_accessor :class_link

  @@types_by_id = {}
  @@types_by_name = {}
  @@elements = {}

  def self.clear
    @@types_by_id.clear
    @@types_by_name.clear
    @@elements.clear
  end

  def self.type_for_id(id)
    @@types_by_id[id]
  end

  def self.type_for_name(name)
    @@types_by_name[name]
  end

  def self.add_element(ele)
    id = ele['idref']
    @@elements[id] = ele
  end

  def self.elements
    @@elements
  end

  def self.add_free_association(assoc)
    case assoc['type']
    when 'uml:Association'
      if assoc.xpath('./ownedEnd').length == 2
        raise "!!! Adding free association -- need to fix"
        r = Relation::Association.new(owner, assoc)
        owner.add_relation(r)
      end
    when 'uml:Realization'
      oid = assoc['client']

      owner = @@types_by_id[oid]
      unless owner.nil?
        r = Relation::Realization.new(owner, assoc)
        # puts "+ Adding relation #{r.stereotype} for #{owner.name}"
        owner.add_relation(r)
      else
        puts "!!! Cannot resolve Realization: #{oid} -> #{sid}"
      end

    else
      puts "!!! unknown association type: #{assoc['type']}"
    end
      
  end

  def self.connect_model
    resolve_types
    connect_children
  end

  def self.connect_children
    @@types_by_id.each do |id, type|
      parent = type.get_parent
      parent.add_child(type) if parent
      type.connect_class_links
    end
  end

  def self.resolve_types
    @@types_by_id.each do |id, type|
      type.resolve_types
      type.check_mixin
    end
  end

  def initialize(model, e)
    @xmi = e
    @id = e['id']

    @extended = @@elements[@id]

    @name = e['name']
    @type = e['type']

    unpack_extended_properties(@extended)

    @operations = e['operations'] || []
    @abstract = e['isAbstract'] || false
    @tags = e['tags']
    @model = model
    @literals = Array(e['literals'])

    @aliased = false
    @class_link = nil

    if e['tags']
      e['tags'].each do |t|
        if t['name'] == 'Alias'
          puts "#{@name} #{t['checked']}" unless t['checked']
          @aliased = t['checked']
        end
      end
    end

    associations = []
    if !is_variable?
      e.element_children.each do |r|
        associations << Relation.create_association(self, r)
      end
      associations.compact!
    end

    @relations, @constraints = associations.partition { |e| e.class != Relation::Constraint }

    @children = []

    @@types_by_id[@id] = self
    @@types_by_name[@name] = self

    @model.add_type(self)
  end

  def add_relation(rel)
    @relations << rel
  end

  def is_opc?
    @model.is_opc?
  end

  def is_class_link?
    @class_link
  end

  def check_mixin
    @mixin = nil
    @relations.each do |r|
      if r.is_mixin?
        @mixin = r.target.type
        # puts "==>  Found Mixin #{r.target.name} for #{@name}"
        return
      end
    end
  end

  def connect_class_links
    if is_class_link?
      # Find the association to the other near and far side
      association = nil
      @relations.delete_if { |a| association = a if a.type == 'UMLAssociation'; association }
      if association
        association.link_target('OrganizedBy', self)
        association.source.type.relations << association
      end
    end
  end

  def is_aliased?
    @aliased
  end

  def resolve_types
    @relations.each do |r|
      r.resolve_types
    end
    if @xmi.include?('classifier')
      @classifier = resolve_type(@xmi['classifier'])
    else
      @classifier = nil
    end
  end

  def variable_data_type
    data_type = get_attribute_like('DataType', /Attribute/)
    if data_type
      data_type.target.type
    elsif @type == 'uml:DataType' or @type == 'uml:Enumeration'
      self
    else
      raise "Could not find data type for #{@name}"
      nil
    end
  end

  def escape_name
    n = @name.gsub('{', '\{').gsub('}', '\}')
    n = "<<#{n}>>" if @type == 'UMLStereotype'
    n
  end

  def add_child(c)
    @children << c
  end

  def stereotype_name
    if @stereotype
      "<<#{@stereotype}>>"
    else
      ''
    end
  end

  def short_name
    @name.gsub(/[ _]/, '')
  end

  def to_s
    "#{@model}::#{@name} -> #{stereotype_name} #{@type} #{@id}"
  end

  def self.resolve_type(ref)
    id = ref['$ref'] if ref
    type = @@types_by_id[id] if id
  end

  def resolve_type(ref)
    Type.resolve_type(ref)
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

  def get_attribute_like(name, stereo = nil)
    # puts "getting attribtue '#{name}' #{stereo.inspect} #{@relations.length}"
    @relations.each do |a|
      # puts "---- Checking '#{a.name}' '#{a.stereotype}'"
      if a.name == name and
        (stereo.nil? or (a.stereotype and a.stereotype =~ stereo))
        # puts "----  >> Found #{a.name}"
        return a
      end
    end
    puts "Recursing"
    return @parent.get_attribute_like(name, stereo) if @parent
    nil
  end

  def get_parent
    if !defined?(@parent)
      @parent = nil
      @relations.each do |r|
        if r.is_a?(Relation::Generalization)
          @parent = r.target.type
        end
      end
    end
    @parent
  end

  def is_a_type?(type)
    @name == type or (@parent and @parent.is_a_type?(type))
  end

  def mixin_properties(f)
    @parent.mixin_properties(f) if @parent
    generate_properties(f)
    generate_relations(f)
  end

  def is_variable?
    @type == 'uml:DataType' or @type == 'uml:PrimitiveType' or
      @type == 'uml:Enumeration' or is_a_type?('BaseVariableType')
  end

  def is_event?
    is_a_type?('BaseEventType')
  end

  def is_reference?
    is_a_type?('References')
  end

  def base_type
    if is_variable?
      "Variable"
    elsif is_event?
      'Event'
    else
      "Object"
    end
  end

  def dependencies
    @relations.select { |r| r.class == Relation::Dependency }
  end

  def realizations
    @relations.select { |r| r.class == Relation::Realization }
  end

end
