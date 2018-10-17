require 'type'
require 'bigdecimal'
require 'set'

module NodeId
  def self.id_to_i(id)
    s = id.unpack('m').first.unpack('L>*')
    v = (BigDecimal(s[1]) * (2 ** 32) + s[2]).modulo(10 ** 6).to_i
    "#{NamespacePrefix}i=#{v}"
  end
end

module Relation
  class Relation
    include NodeId
    attr_reader :node_id

    def resolve_node_ids
      @node_id = NodeId.id_to_i(@id)
    end

    def reference_type_alias
      ref = reference_type
      if Aliases.include?(ref)
        ref
      elsif NodeIds.include?(ref)
        NodeIds[ref]
      elsif stereotype
        stereotype.node_id
      else
        raise "!!!! Cannot find reference type for #{@owner.name}::#{@name}"
      end
    end
  end
end

class Type
  attr_reader :node_id
  include NodeId

  @@mixin_suffix = 0
  
  def self.check_ids
    check = Hash.new
    @@types_by_id.each do |id, t|
      ino = t.node_id
      if check.include?(ino)
        puts "Duplicate generated id: #{id} - #{ino}: #{check[ino].name}"
      end
      check[ino] = t
    end
  end

  def self.resolve_node_ids
    @@types_by_id.each do |id, t|
      t.resolve_node_ids
    end
  end

  def resolve_node_ids
    if NodeIds.include?(@name)
      @node_id = NodeIds[@name]
      @node_alias = @name if @aliased
    else
      @node_id = NodeId.id_to_i(@id)
    end

    @relations.each { |r| r.resolve_node_ids }
  end

  def node_alias
    @node_alias || @node_id
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

  def reference(rel, suffix = '', forward: true)
    cmt = REXML::Comment.new(" #{rel.reference_type} - - #{rel.name} #{rel.node_id}#{suffix} #{rel.target.type.name} (forward: #{forward}) ")
    ref = REXML::Element.new('Reference')
    ref.add_attribute('ReferenceType', rel.reference_type_alias)
    ref.add_attribute('IsForward', 'false') unless forward
    ref.add_text("#{rel.node_id}#{suffix}")
    [cmt, ref]
  end

  def node_reference(name, type, target, forward: true)
    cmt = REXML::Comment.new(" #{type} - - #{name} #{target} (forward: #{forward}) ")
    ref = REXML::Element.new('Reference')
    ref.add_attribute('ReferenceType', type)
    ref.add_attribute('IsForward', 'false') unless forward
    ref.add_text(target)
    [cmt, ref]
  end

  def variable_property(ref, suffix = '')
    ele, refs = node('UAVariable', "#{ref.node_id}#{suffix}", ref.name, data_type: ref.target.type.node_alias,
                     value_rank: -1)
    node_reference(ref.target.type.name, 'HasTypeDefinition', ref.target_node_id).
      each { |r| refs << r }
    node_reference(ref.rule, 'HasModellingRule', NodeIds[ref.rule]).
      each { |r| refs << r }
    node_reference(ref.owner.name, 'HasProperty', ref.owner.node_id, forward: false).
      each { |r| refs << r }
    
    ele    
  end

  def component(ref, suffix = '')
    ele, refs = node('UAObject', "#{ref.node_id}#{suffix}", ref.name)
    node_reference(ref.target.type.name, 'HasTypeDefinition', ref.target.type.node_id).
      each { |r| refs << r }
    node_reference(ref.rule, 'HasModellingRule', NodeIds[ref.rule]).
      each { |r| refs << r }
    node_reference(ref.owner.name, 'HasProperty', ref.owner.node_id, forward: false).
      each { |r| refs << r }
    
    ele    
  end

  def relationships(suffix = '')
    nodes = []
    refs = []
    
    @relations.each do |a|
      if !a.is_attribute? and a.name
        if a.is_property?
          refs.concat(reference(a, suffix))
          nodes << variable_property(a, suffix)
        elsif a.is_a? Relation::Association
          refs.concat(reference(a, suffix))
          nodes << component(a, suffix)
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
    nodes, refs = relationships(@@mixin_suffix)
    [Array(pnodes).concat(nodes), Array(prefs).concat(refs)]
  end

  def generate_object_or_variable(root)
    if is_a_type?('BaseObjectType')
      node, refs = node('UAObjectType', node_id, @name, abstract: @abstract)
    elsif is_a_type?('BaseDataVariableType')
      # Need to add data type
      node, refs = node('UAVariableType', node_id, @name, abstract: @abstract, value_rank: -1,
                        data_type: variable_data_type.node_alias)
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
        @@mixin_suffix += 1
      end
      
      nodes, references = relationships
      references.each { |r| refs << r }
      nodes.each { |n| root << n }
    end
  end

  def generate_enumeration(root)
    puts "  => Enumeration #{@name}"
    node, refs = node('UADataType', node_id, @name)
    # node.add_element('Description').add_text(@documentation) if @documentation
    node_reference('Enumeration', 'HasSubtype', NodeIds['Enumeration'], forward: false).
      each { |r| refs << r }
    node_reference('EnumStrings', 'HasProperty', "#{node_id}1").
      each { |r| refs << r }
    

    defs = node.add_element('Definition', { 'Name' => @name })
    @literals.each do |l|
      name, value = l['name'].split('=')
      field = defs.add_element('Field', { 'Name' => name, 'Value' => value })
      field.add_element('Description').add_text(l['documentation']) if l['documentation']
    end

    root << node
    
    # now create the enum strings property
    node, refs = node('UAVariable', "#{node_id}1", 'EnumStrings', data_type: 'LocalizedText',
                      value_rank: 1)
    node_reference('PropertyType', 'HasTypeDefinition', NodeIds['PropertyType']).
      each { |r| refs << r }
    node_reference('Mandatory', 'HasModellingRule', NodeIds['Mandatory']).
      each { |r| refs << r }
    node_reference('Owner', 'HasProperty', node_id, forward: false).
      each { |r| refs << r }

    values = node.add_element('Value').
               add_element('ListOfLocalizedText',
                           { 'xmlns' => 'http://opcfoundation.org/UA/2008/02/Types.xsd'})
        
    @literals.each do |l|
      name, _ = l['name'].split('=')
      text = values.add_element('LocalizedText')
      text.add_element('Locale')
      text.add_element('Text').add_text(name)
    end

    root << node
  end

  def generate_data_type(root)
    puts "  => DataType #{@name}"
    node, refs = node('UADataType', node_id, @name)
    #node.add_element('Description').add_text(@documentation) if @documentation
    node_reference('BaseDataType', 'HasSubtype', NodeIds['BaseDataType'], forward: false).
      each { |r| refs << r }
    
    defs = node.add_element('Definition', { 'Name' => @name })
    @relations.each do |r|
      field = defs.add_element('Field', { 'Name' => r.name, 'DataType' =>  r.target.type.node_alias })
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


