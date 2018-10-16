require 'type'
require 'bigdecimal'
require 'set'

module NodeId
  def self.id_to_i(id)
    s = id.unpack('m').first.unpack('L>*')
    v = (BigDecimal(s[1]) * (2 ** 32) + s[2]).modulo(2**32).to_i
    "ns=1;i=#{v}"
  end

  def self.node_id_for(name, id)
    if Aliases.include?(name)
      name
    elsif NodeIds.include?(name)
      NodeIds[name]
    elsif id
      id_to_i(id)
    else
      nil
    end
  end

  def resolve_node_id(id)
    type = Type.types[id]
    if type
      type.node_id
    else
      NodeId.id_to_i(id)
    end
  end  
end

module Relation
  class Relation
    include NodeId

    def node_id
      NodeId.id_to_i(@id)
    end
    
    def reference_type_id
      if Aliases.include?(reference_type)
        reference_type
      else
        resolve_node_id(reference_type)
      end
    end

    def reference_type_node_id
      if Aliases.include?(reference_type)
        Aliases[reference_type]
      else
        resolve_node_id(reference_type)
      end
    end
  end

  class Association
    def resolve_data_type
      @target.type.node_id
    end

    def target_node_id
      if is_folder?
        NodeIds['FolderType']
      else
        @target.type.node_id
      end
    end    
  end

  class Attribute
    def resolve_data_type
      if Hash === @data_type
        @target.type = Type.resolve_type(@data_type)
      else
        return @data_type if Aliases.include?(@data_type)
        NodeIds[@data_type]
      end
    end
  end
end

class Type
  include NodeId
  
  def node_id
    unless defined?(@node_id)
      @node_id = NodeId.node_id_for(@name, @id)
    end
    @node_id
  end

  def self.check_ids
    check = Hash.new
    @@types.each do |id, t|
      ino = t.node_id
      if check.include?(ino)
        puts "Duplicate generated id: #{id} - #{ino}: #{check[ino].name}"
      end
      check[ino] = t
    end
  end

  def node(type, id, name, display_name: nil, abstract: false, value_rank: nil, data_type: nil)
    node = REXML::Element.new(type)
    node.add_attributes({ 'NodeId' => id,
                          'BrowseName' => "1:#{name}"})
    node.add_attribute('IsAbstract', 'true') if abstract
    node.add_attribute('ValueRank', value_rank) if value_rank
    node.add_attribute('DataType', data_type) if data_type

    node.add_element('DisplayName').add_text(display_name || name)
    refs = node.add_element('References')
    
    [node, refs]
  end

  def reference(rel, forward: true)
    cmt = REXML::Comment.new(" #{rel.reference_type} -- #{rel.name} #{rel.node_id} #{rel.target.name} (forward: #{forward}) ")
    ref = REXML::Element.new('Reference')
    ref.add_attribute('ReferenceType', rel.reference_type_id)
    ref.add_attribute('IsForward', 'false') unless forward
    ref.add_text(rel.node_id)
    [cmt, ref]
  end

  def node_reference(name, type, target, forward: true)
    cmt = REXML::Comment.new(" #{type} -- #{name} #{target} (forward: #{forward}) ")
    ref = REXML::Element.new('Reference')
    ref.add_attribute('ReferenceType', type)
    ref.add_attribute('IsForward', 'false') unless forward
    ref.add_text(target)
    [cmt, ref]
  end

  def variable_property(ref)
    ele, refs = node('UAVariable', ref.node_id, ref.name, data_type: ref.resolve_data_type_name,
               value_rank: -1)
    node_reference(ref.reference_type, 'HasTypeDefinition', ref.reference_type_node_id).
      each { |r| refs << r }
    node_reference(ref.rule, 'HasModelingRule', NodeIds[ref.rule]).
      each { |r| refs << r }
    node_reference(ref.owner.name, 'HasProperty', ref.owner.node_id, forward: false).
      each { |r| refs << r }
    
    ele    
  end

  def component(ref)
    ele, refs = node('UAObject', ref.node_id, ref.name)
    node_reference(ref.target_node_name, 'HasTypeDefinition', ref.target_node_id).
      each { |r| refs << r }
    node_reference(ref.rule, 'HasModelingRule', NodeIds[ref.rule]).
      each { |r| refs << r }
    node_reference(ref.owner.name, 'HasProperty', ref.owner.node_id, forward: false).
      each { |r| refs << r }
    
    ele    
  end

  def relationships
    nodes = []
    refs = []
    
    @relations.each do |a|
      if !a.is_attribute? and a.name
        if a.is_property?
          refs.concat(reference(a))
          nodes << variable_property(a)
        elsif a.is_a? Relation::Association
          refs.concat(reference(a))          
          nodes << component(a)
        end
      end
    end
    [nodes, refs]
  end

  def relation_type(r)
    stereo = r['stereotype'] && resolve_type_name(r['stereotype'])
    if !Aliases.include?(stereo)
      st = resolve_type(r['stereotype'])
      if st
        stereo = st.node_id
      else
        puts "***** Cannot find stereotype for #{r.inspect}"
      end
    end
    unless stereo
      puts "Relation #{r['name']} has no stereotype"
      stereo = 'HasComponent'
    end
    stereo
  end

  def add_mixin_relations
    pnodes, prefs = @parent.add_mixin_relations if @parent
    nodes, refs = relationships
    [Array(pnodes).concat(nodes), Array(prefs).concat(refs)]
  end

  def generate_object_or_variable(root)
    if is_a_type?('BaseObjectType')
      node, refs = node('UAObjectType', node_id, @name, abstract: @abstract)
    elsif is_a_type?('BaseDataVariableType')
      # Need to add data type
      node, refs = node('UAVariableType', node_id, @name, abstract: @abstract, value_rank: -1,
                        data_type: variable_data_type)
    end
    
    if node
      puts "  -> Generating nodeset for #{@name}"
      root << node
      
      node_reference(@parent.name, 'HasSubtype', @parent.node_id, forward: false).
        each { |r| refs << r }
      
      if @mixin
        nodes, references = @mixin.add_mixin_relations
        references.each { |r| refs << r }
        nodes.each { |n| root << n }
      end
      
      nodes, references = relationships
      references.each { |r| refs << r }
      nodes.each { |n| root << n }
    end
  end

  def generate_enumeration(root)
    puts "    => Enumeration #{@name}"
    node, refs = node('UADataType', node_id, @name)
    node_reference('Enumeration', 'HasSubtype', NodeIds['Enumeration'], forward: false).
      each { |r| refs << r }
    node.add_element('Description').add_text(@documentation) if @documentation

    defs = node.add_element('Definition', { 'Name' => @name })
    @literals.each do |l|
      name, value = l['name'].split('=')
      field = defs.add_element('Field', { 'Name' => name, 'Value' => value })
      field.add_element('Description').add_text(l['documentation']) if l['documentation']
    end
        
    root << node
  end

  def generate_data_type(root)
    puts "   => DataType #{@name}"
    node, refs = node('UADataType', node_id, @name)
    node_reference('BaseDataType', 'HasSubtype', NodeIds['BaseDataType'], forward: false).
      each { |r| refs << r }
    node.add_element('Description').add_text(@documentation) if @documentation
    
    defs = node.add_element('Definition', { 'Name' => @name })
    @relations.each do |r|
      field = defs.add_element('Field', { 'Name' => r.name, 'DataType' =>  r.resolve_data_type })
      field.add_element('Description').add_text(r.documentation) if r.documentation
    end

    root << node
  end

  def generate_nodeset(root)
    return if stereotype_name == '<<Dynamic Type>>'

    if @type == 'UMLEnumeration'
      generate_enumeration(root)
    elsif @type == 'UMLDataType'
      generate_data_type(root)      
    else
      generate_object_or_variable(root)
    end
  end
end


