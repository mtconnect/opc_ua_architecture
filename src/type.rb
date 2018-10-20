require 'relation'

class Type
  attr_reader :name, :id, :type, :model, :json, :parent, :children, :relations       

  @@types_by_id = {}
  @@types_by_name = {}

  def self.type_for_id(id)
    @@types_by_id[id]
  end

  def self.type_for_name(name)
    @@types_by_name[name]
  end
  
  def self.connect_children
    @@types_by_id.each do |id, type|
      parent = type.get_parent
      parent.add_child(type) if parent
    end
  end

  def self.resolve_types
    @@types_by_id.each do |id, type|
      type.resolve_types
      type.check_mixin
    end
  end

  def initialize(model, e)
    @name = e['name']
    @id = e['_id']
    @type = e['_type']
    @documentation = e['documentation']
    @operations = e['operations'] || []
    @abstract = e['isAbstract'] || false
    @model = model
    @literals = Array(e['literals'])

    @aliased = false
    
    if e['tags']
      e['tags'].each do |t|
        if t['name'] == 'Alias'
          puts "#{@name} #{t['checked']}" unless t['checked']
          @aliased = t['checked']
        end
      end
    end

    associations = Array(e['attributes']).dup.concat(Array(e['ownedElements'])).
                     concat(Array(e['slots'])).map do |r|
      Relation.create_association(self, r)
    end.compact

    @relations, @constraints = associations.partition { |e| e.class != Relation::Constraint }
    
    @children = []
    @json = e

    @@types_by_id[@id] = self
    @@types_by_name[@name] = self

    @model.add_type(self)
  end

  def is_opc?
    @model.is_opc?
  end

  def check_mixin
    @mixin = nil
    @relations.each do |r|
      if r.is_mixin?
        @mixin = r.target.type
        puts "==>  Found Mixin #{r.target.name} for #{@name}"
        return
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
    if @json.include?('classifier')
      @classifier = resolve_type(@json['classifier'])
    else
      @classifier = nil
    end
    if @json.include?('stereotype')
      @stereotype = resolve_type(@json['stereotype'])
    else
      @stereotype = nil
    end         
  end

  def variable_data_type
    data_type = get_attribute_like(/DataType$/, /Attribute/)
    if data_type
      data_type.target.type
    else
      raise "Could not find data type for #{@name}"
      nil
    end
  end

  def mandatory(obj)
    if obj['multiplicity'] == '0..1' or obj['multiplicity'] == '0..*'
      'Optional'
    else
      'Mandatory'
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
      "<<#{@stereotype.name}>>"
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

  def connect_links
    @relations.each do |r|
      if r.type == 'UMLAssociationClassLink'
        puts "********* Connecting relation for #{@name}"
        @relations.each do |r|
          if r.type == 'UMLAssociation'            
            source = r.source
            puts "********* -> Connecting to #{source.name}"
            source.relations << r if source
            return
          end
        end
      end
    end
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

  def get_attribute_like(pattern, stereo = nil)
    @relations.each do |a|
      # puts "---- Checking #{a.name} #{pattern.inspect} #{stereo.inspect}"
      if a.name =~ pattern and
        (stereo.nil? or (a.stereotype and a.stereotype.name =~ stereo))
        # puts "----  >> Found #{a.name}"
        return a
      end
    end
    return @parent.get_attribute_like(pattern, stereo) if @parent
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

  def base_type
    if @type == 'UMLDataType' or is_a_type?('BaseDataVariableType')
      "Variable"
    elsif is_a_type?('BaseEventType')
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
