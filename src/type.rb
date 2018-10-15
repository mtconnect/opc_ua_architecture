
class Type
  attr_reader :name, :id, :type, :model, :json, :parent, :children

  @@types = {}

  def self.types
    @@types
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
    @attributes = e['attributes'] || []
    @relations = e['ownedElements'] || []
    @operations = e['operations'] || []
    @abstract = e['isAbstract'] || false
    @model = model

    @children = []

    @json = e

    @@types[@id] = self

    @model.add_type(self)
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

  def get_attribute_like(pattern)
    if @attributes
      @attributes.each do |a|
        return a if a['name'] =~ pattern
      end
      @relations.each do |a|
        if a['end1'] and a['end2']
          name = a['name'] || a['end1']['name']
          if name  and name =~ pattern
            type = resolve_type_name(a['end2']['reference'])
            return type if type
          end
        end
      end
    end
    return @parent.get_attribute_like(pattern) if @parent
    nil
  end
    
  def get_parent
    if !defined?(@parent)
      @parent = nil
      @relations.each do |rel|
        if rel['_type'] == 'UMLGeneralization'
          parent_id = rel['target']['$ref']
          @parent = @@types[parent_id]
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

  def dependencies
    depends = @relations.select { |r| r['_type'] == 'UMLDependency' }
  end

  def find_stereotypes_and_targets(list)
    list.map do |d|
      stereo = resolve_type(d['stereotype'])
      target = resolve_type(d['target'])
      if stereo and target
        [stereo, target]
      else
        nil
      end
    end.compact
  end

  def dependency_targets
    find_stereotypes_and_targets(dependencies)
  end
      
  def realizations
    depends = @relations.select { |r| r['_type'] == 'UMLRealization' }
  end
    
  def realization_targets
    find_stereotypes_and_targets(realizations)
  end
end
