require 'type'
require 'bigdecimal'
require 'set'

module NodeId
  def self.id_to_i(id)
    s = id.unpack('m').first.unpack('L>*')
    v = (BigDecimal(s[1]) * (2 ** 32) + s[2]).modulo(10 ** 6).to_i
    "ns=#{Namespace};i=#{v}"
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

  class Association
    def target_node_id
      if is_folder?
        NodeIds['FolderType']
      else
        @target.type.node_id
      end
    end
    
    def target_node_id
      if is_folder?
        NodeIds['FolderType']
      else
        @target.type.node_id
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

  def node(type, id, name, display_name: nil, abstract: false, value_rank: nil, data_type: nil, symmetric: nil,
           prefix: true)
    node = REXML::Element.new(type)

    browse = prefix ? "#{Namespace}:#{name}" : name
    node.add_attributes({ 'NodeId' => id,
                          'BrowseName' => browse })
    node.add_attribute('IsAbstract', 'true') if abstract
    node.add_attribute('ValueRank', value_rank) if value_rank
    node.add_attribute('DataType', data_type) if data_type
    node.add_attribute('Symmetric', symmetric) if !symmetric.nil?

    node.add_element('DisplayName').add_text(display_name || name)
    refs = node.add_element('References')
    
    [node, refs]
  end
  
  def node_reference(refs, name, type, target, target_type = nil, forward: true)
    refs << REXML::Comment.new(" #{type} - - #{name} #{target} #{target_type} (forward: #{forward}) ")
    ref = REXML::Element.new('Reference')
    ref = refs.add_element('Reference', { 'ReferenceType' => type })
    ref.add_attribute('IsForward', 'false') unless forward
    ref.add_text(target)
  end
  
  def reference(refs, rel, suffix = '', forward: true)
    node_reference(refs, rel.name, rel.reference_type_alias,
                   "#{rel.node_id}#{suffix}", rel.target.type.name,
                   forward: forward)
  end

  def add_value(ele, ref)
    value = ele.add_element('Value')
    resolved = ref.target.type.get_attribute_like(/Value/) || ref
    ref_type = resolved.target.type
    
    if ref.value and ref.value[0] == "["
      values = ref.value[1..-2].split(',')
      list = value.add_element("ListOf#{ref_type.name}", { 'xmlns' => "http://opcfoundation.org/UA/2008/02/Types.xsd"})
      values.each do |v|
        list.add_element(ref_type.name).add_text(v)
        end
    else
      value.add_element(ref_type.name, { 'xmlns' => "http://opcfoundation.org/UA/2008/02/Types.xsd"}).
        add_text(ref.value)
    end
  end

  def variable_property(ref, suffix = '')
    ele, refs = node('UAVariable', "#{ref.node_id}#{suffix}", ref.name, data_type: ref.target.type.node_alias,
                     value_rank: -1, prefix: !is_opc_instance?)
    node_reference(refs, ref.target.type.name, 'HasTypeDefinition', ref.target_node_id, ref.target_node_name)
    node_reference(refs, ref.rule, 'HasModellingRule', NodeIds[ref.rule]) unless ref.type == 'UMLSlot'
    node_reference(refs, ref.owner.name, 'HasProperty', ref.owner.node_id, forward: false)

    # Add values for slots
    add_value(ele, ref) if ref.type == 'UMLSlot'
    
    ele    
  end

  def component(ref, suffix = '')
    ele, refs = node('UAObject', "#{ref.node_id}#{suffix}", ref.name)
    node_reference(refs, ref.target.type.name, 'HasTypeDefinition', ref.target.type.node_id)
    node_reference(refs, ref.rule, 'HasModellingRule', NodeIds[ref.rule])
    node_reference(refs, ref.owner.name, 'HasProperty', ref.owner.node_id, forward: false)
    
    ele    
  end

  def is_opc_instance?
    @type == 'UMLObject' and @classifier.is_opc?
  end
  
  def relationships(refs, suffix = '')
    nodes = []

    @relations.each do |a|
      if !a.is_attribute? and a.name
        if a.is_property?
          reference(refs, a, suffix)
          nodes << variable_property(a, suffix)
        elsif a.is_a? Relation::Association
          if @type == 'UMLObject' && a.target.type.is_opc?
            node_reference(refs, a.name, a.reference_type_alias,
                           a.target.type.node_id, a.target.type.name,
                           forward: a.target.navigable)
          else
            reference(refs, a, suffix)
            nodes << component(a, suffix)
          end
        end
      end
    end
    nodes
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

  def add_mixin_relations(refs)
    pnodes = @parent.add_mixin_relations(refs) if @parent
    nodes = relationships(refs, @@mixin_suffix)
    Array(pnodes).concat(nodes)
  end

  def generate_object_or_variable(root)
    if is_a_type?('BaseObjectType') or is_a_type?('BaseEventType')
      node, refs = node('UAObjectType', node_id, @name, abstract: @abstract)
    elsif is_a_type?('BaseDataVariableType')
      node, refs = node('UAVariableType', node_id, @name, abstract: @abstract, value_rank: -1,
                        data_type: variable_data_type.node_alias)
    elsif is_a_type?('References')
      symmetric = get_attribute_like(/Symmetric$/, /Attribute/)
      is_symmetric = symmetric.default
      node, refs = node('UAReferenceType', node_id, @name, abstract: @abstract, symmetric: is_symmetric)
    elsif  @stereotype and @stereotype.name == 'mixin'
      puts "** Skipping mixin #{@name}"
    else
      puts "!! Do not know how to generate #{@name} #{@type}"
    end
    
    if node
      puts "  -> Generating nodeset for #{@name}"
      root << node
      
      node_reference(refs, @parent.name, 'HasSubtype', @parent.node_id, forward: false)
      
      if @mixin
        nodes = @mixin.add_mixin_relations(refs)
        nodes.each { |n| root << n }
        @@mixin_suffix += 1
      end
      
      nodes = relationships(refs)
      nodes.each { |n| root << n }
    end
  end

  def generate_enumeration(root)
    puts "  => Enumeration #{@name}"
    node, refs = node('UADataType', node_id, @name)
    # node.add_element('Description').add_text(@documentation) if @documentation
    node_reference(refs, 'Enumeration', 'HasSubtype', NodeIds['Enumeration'], forward: false)
    node_reference(refs, 'EnumStrings', 'HasProperty', "#{node_id}1")

    value_ele = REXML::Element.new('Value')
    values = value_ele.add_element('ListOfLocalizedText',
                               { 'xmlns' => 'http://opcfoundation.org/UA/2008/02/Types.xsd'})
    
    defs = node.add_element('Definition', { 'Name' => @name })
    @literals.each do |l|
      name, value = l['name'].split('=')
      field = defs.add_element('Field', { 'Name' => name, 'Value' => value })
      field.add_element('Description').add_text(l['documentation']) if l['documentation']

      text = values.add_element('LocalizedText')
      text.add_element('Locale')
      text.add_element('Text').add_text(name)      
    end

    root << node
    
    # now create the enum strings property
    node, refs = node('UAVariable', "#{node_id}1", 'EnumStrings', data_type: 'LocalizedText',
                      value_rank: 1)
    node_reference(refs, 'PropertyType', 'HasTypeDefinition', NodeIds['PropertyType'])
    node_reference(refs, 'Mandatory', 'HasModellingRule', NodeIds['Mandatory'])
    node_reference(refs, 'Owner', 'HasProperty', node_id, forward: false)

    node << value_ele

    root << node
  end

  def generate_data_type(root)
    puts "  => DataType #{@name}"
    node, refs = node('UADataType', node_id, @name)
    #node.add_element('Description').add_text(@documentation) if @documentation
    node_reference(refs, 'BaseDataType', 'HasSubtype', NodeIds['BaseDataType'], forward: false)
    
    defs = node.add_element('Definition', { 'Name' => @name })
    @relations.each do |r|
      field = defs.add_element('Field', { 'Name' => r.name, 'DataType' =>  r.target.type.node_alias })
      field.add_element('Description').add_text(r.documentation) if r.documentation
    end

    root << node
  end

  def generate_instance(root)
    puts "  => Object Instance #{@name}"
    node, refs = node('UAObject', node_id, @name)
    root << node
    
    node_reference(refs, @classifier.name, 'HasTypeDefinition', @classifier.node_id)

    nodes = relationships(refs)
    nodes.each { |n| root << n }
  end


  def generate_nodeset(root)
    return if stereotype_name == '<<Dynamic Type>>'

    if @type == 'UMLEnumeration'
      generate_enumeration(root)
    elsif @type == 'UMLDataType'
      generate_data_type(root)      
    elsif @type == 'UMLObject'
      generate_instance(root)
    else
      generate_object_or_variable(root)
    end
  end
end


