require 'relation'

class Type
  attr_reader :name, :id, :type, :model, :json, :parent, :children, :relations

  @@types = {}

  def self.types
    @@types
  end

  def self.connect_children
    @@types.each do |id, type|
      parent = type.get_parent
      parent.add_child(type) if parent

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

    @relations = Array(e['attributes']).dup.concat(Array(e['ownedElements'])).map do |r|
      Relation.create_association(self, r)
    end.compact
    
    @children = []
    @json = e

    @@types[@id] = self

    @model.add_type(self)
  end

  def check_mixin
    @mixin = nil
    @relations.each do |r|
      if r.is_a?(Relation::Realization) and r.stereotype.name == 'Mixes In'
        @mixin = r.target
        # puts "==>  Found Mixin #{r.target.name} for #{@name}"
        return
      end
    end
  end

  def variable_data_type
    @relations.each do |a|
      if a.is_attribute? and a.stereotype.name =~ /Override/
        return a.resolve_data_type
      end
    end
    nil
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
    if !defined?(@stereotype) and  @json['stereotype']
      @stereotype = resolve_type(@json['stereotype'])
    elsif !defined?(@stereotype)
      @stereotype = nil
    end
      
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
    type = @@types[id] if id
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

  def get_attribute_like(pattern)
    @relations.each do |a|
      return a if a.name =~ pattern
    end
    return @parent.get_attribute_like(pattern) if @parent
    nil
  end
    
  def get_parent
    if !defined?(@parent)
      @parent = nil
      @relations.each do |r|
        if r.is_a?(Relation::Generalization)
          @parent = r.target
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

  def find_stereotypes_and_targets(list)
    list.map do |d|
      stereo = d.stereotype
      target = d.target
      if stereo and target
        [stereo, target]
      else
        nil
      end
    end.compact
  end

  def dependencies
    @relations.select { |r| r.class == Relation::Dependency }
  end

  def dependency_targets
    find_stereotypes_and_targets(dependencies)
  end
      
  def realizations
    @relations.select { |r| r.class == Relation::Realization }
  end
    
  def realization_targets
    find_stereotypes_and_targets(realizations)
  end
end
