require 'relation'
require 'extensions'

class Type
  include Extensions
  
  attr_reader :name, :id, :type, :model, :json, :parent, :children, :relations, :stereotype,
              :constraints, :extended, :documentation, :literals, :invariants
  attr_accessor :class_link

  class LazyPointer
    @@pointers = []

    def self.resolve
      @@pointers.each do |o|
        o.resolve
      end
    end

    def initialize(obj)
      @tid = @type = nil
      @lazy_lambdas = []
      
      case obj
      when String
        @tid = obj
        @type = Type.type_for_id(@tid)
        @@pointers << self unless @type

      when Type
        @type = obj
        @tid = @type.id

      else
        raise "Pointer created for unknown type: #{obj.class}"
      end
    end

    def lazy(&block)
      if @type
        @type.instance_eval(&block)
      else
        @lazy_lambdas << block
      end
    end

    def id
      @tid
    end

    def resolved?
      !@type.nil?
    end

    def internal?
      @tid =~ /^EA/
    end

    def resolve
      unless @type
        @type = Type.type_for_id(@tid)
        if @type.nil? and @tid !~ /^EAID/
          if @tid =~ /^EA[^_]+_([A-Za-z]+)/
            # puts "Could not find #{@tid}, Looking up type by name: #{$1}"
            @type = Type.type_for_name($1)
            # puts "  Found type for #{@type.name}" if @type
          else
            @type = Type.type_for_name(@tid)
          end
        end
        
        if @type
          @lazy_lambdas.each do |block|
            @type.instance_eval(&block)
          end
        else
          puts "Warn: Cannot find type for #{@tid}"
        end
      end
      
      !@type.nil?
    end

    def method_missing(m, *args, &block)
      unless @type
        raise "!!! Calling #{m} on unresolved type #{@tid}"
      else
        @type.send(m, *args, &block)
      end
    end    
  end

  @@types_by_id = {}
  @@types_by_name = {}

  def self.clear
    @@types_by_id.clear
    @@types_by_name.clear
  end

  def self.type_for_id(id)
    @@types_by_id[id]
  end

  def self.type_for_name(name)
    @@types_by_name[name]
  end

  def self.add_free_association(assoc)
    case assoc['type']
    when 'uml:Association'
      if assoc.xpath('./ownedEnd').length == 2
        raise "!!! Adding free association -- need to fix: #{assoc.inspect}"
        r = Relation::Association.new(owner, assoc)
        owner.add_relation(r)
      end
      
    when 'uml:Realization'
      oid = assoc['client']
      owner = LazyPointer.new(oid)
      r = Relation::Realization.new(owner, assoc)
      # puts "+ Adding realization #{r.stereotype} for #{r.is_mixin?} -- #{oid}"
      # puts "   ++ #{owner.name}" if owner.resolved?
      owner.lazy { self.add_relation(r) }

    when 'uml:Dependency'
      oid = assoc['client']
      owner = LazyPointer.new(oid)
      r = Relation::Dependency.new(owner, assoc)
      owner.lazy { self.add_relation(r) }      
      # puts "+ Adding dependency #{r.stereotype} for #{owner.name}"

    else
      puts "!!! unknown association type: #{assoc['type']}"
    end
      
  end

  def self.connect_model
    Type::LazyPointer.resolve
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

    @extended = e.at("//element[@idref='#{@id}']")

    @name = e['name']
    @type = e['type']

    unpack_extended_properties(@extended)

    @operations = e['operations'] || []
    @abstract = e['isAbstract'] || false
    @model = model
    @literals = []
    if @type == 'uml:Enumeration'
      e.ownedLiteral.each do |lit|
        @literals << lit['name'].split('=')
      end
    end

    @aliased = false
    @class_link = nil

    associations = []
    if @type == 'uml:InstanceSpecification'
      @extended.xpath('./attributes/attribute').each do |a|
        associations << Relation.create_association(self, a)
      end
      @extended.xpath('./links/Association').each do |l|
        id = l['id']
        assoc = l.document.at("//ownedAttribute[@association='#{id}']")
        associations << Relation.create_association(LazyPointer.new(l['start']), assoc)
      end
    elsif @type != 'uml:PrimitiveType' and @type != 'uml:Enumeration'
      e.element_children.each do |r|
        associations << Relation.create_association(self, r)
      end
    end
    associations.compact!

    #@relations, @constraints = associations.partition { |e| e.class != Relation::Constraint }
    @constraints = {}
    @invariants = {}
    @relations = associations

    @children = []

    # puts "Adding type #{@name} for id #{@id}"

    @@types_by_id[@id] = self
    @@types_by_name[@name] = self

    if @xmi['classifier']
      @classifier = LazyPointer.new(@xmi['classifier'])
    else
      @classifier = nil
    end
    
    @model.add_type(self)
  end

  def resolved?
    true
  end

  def add_relation(rel)
    @relations << rel
  end

  def relation(name)
    rel, = @relations.find { |a| a.name == name }
    rel
  end

  def is_opc?
    @model.is_opc?
  end

  def is_class_link?
    @class_link
  end

  def check_mixin
    @mixin = nil
    # puts "Checking mixin for #{@name}"
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
      @relations.delete_if { |a| association = a if a.type == 'uml:Association'; association }
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
  end

  def variable_data_type
    data_type = get_attribute_like('DataType', /Attribute/)
    if data_type
      data_type.target.type
    elsif @type == 'uml:DataType' or @type == 'uml:Enumeration'
      self
    else
      raise "Could not find data type for #{@type} #{@name} #{@stereotype} "
      nil
    end
  end

  def escape_name
    n = @name.gsub('{', '\{').gsub('}', '\}')
    n = "<<#{n}>>" if @type == 'uml:Stereotype'
    n
  end

  def add_child(c)
    @children << c
  end

  def stereotype_name
    if @stereotype and @stereotype != 'stereotype'
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
    type = @@types_by_id[ref]
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
    #puts "getting attribtue '#{@name}::#{name}' #{stereo.inspect} #{@relations.length}"
    @relations.each do |a|
      #puts "---- Checking '#{a.name}' '#{a.stereotype}'"
      if a.name == name and
        (stereo.nil? or (a.stereotype and a.stereotype =~ stereo))
        #puts "----  >> Found #{a.name}"
        return a
      end
    end
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
