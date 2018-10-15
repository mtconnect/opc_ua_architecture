require 'type'
require 'bigdecimal'
require 'set'

class Type
  def self.id_to_i(id)
    s = id.unpack('m').first.unpack('L>*')
    v = (BigDecimal(s[1]) * (2 ** 32) + s[2]).modulo(2**32).to_i
    "ns=1;i=#{v}"
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
    type = @@types[id]
    if type
      type.node_id
    else
      Type.id_to_i(id)
    end
  end

  def node_id
    unless defined?(@node_id)
      @node_id = Type.node_id_for(@name, @id)
    end
    @node_id
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

  def reference(name, type, target, target_name = nil, forward: true)
    cmt = REXML::Comment.new(" #{type} -- #{name} #{target} #{target_name} (forward: #{forward}) ")
    ref = REXML::Element.new('References')
    ref.add_attribute('ReferenceType', type)
    ref.add_attribute('IsForward', 'false') unless forward
    ref.add_text(target)
    [cmt, ref]
  end

  def variable_property(id, name, var_type, data_type, rule, parent_id, parent_name)
    ele, refs = node('UAVariable', id, name, data_type: data_type,
               value_rank: -1)
    reference(var_type, 'HasTypeDefinition', var_type).
      each { |r| refs << r }
    reference(rule, 'HasModelingRule', NodeIds[rule]).
      each { |r| refs << r }
    reference(parent_name, 'HasProperty', parent_id, forward: false).
      each { |r| refs << r }
    
    ele    
  end

  def attributes
    nodes = []
    refs = []
    
    @attributes.each do |a|
      stereo = a['stereotype'] && resolve_type_name(a['stereotype'])
      unless stereo =~ /Attribute/
        name = a['name']
        id = resolve_node_id(a['_id'])
        var_type = NodeIds['PropertyType']
        data_type = resolve_data_type(a['type'])
        
        refs.concat(reference(name, 'HasProperty', id))
        nodes << variable_property(id, name,
                                   data_type, var_type,
                                   mandatory(a), node_id, @name)
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
  
  def resolve_data_type(type)
    return type if Aliases.include?(type)
    NodeIds[type]
  end

  def component(id, name, type_id, type_name, rule, rel_type, parent_id, parent_name)
    ele, refs = node('UAObject', id, name)
    reference(type_name, 'HasTypeDefinition', type_id).
      each { |r| refs << r }
    reference(rule, 'HasModelingRule', NodeIds[rule]).
      each { |r| refs << r }
    reference(parent_name, rel_type, parent_id, forward: false).
      each { |r| refs << r }
    
    ele    
  end

    
  def relationships
    refs = []
    nodes = []
    
    @relations.each do |r|
      if r['_type'] == 'UMLAssociation'
        target = resolve_type(r['end2']['reference'])
        if target and (r['name'] or r['end1']['name'])
          name = r['end1']['name'] || r['name']
          rel_type = relation_type(r)
          target = resolve_type(r['end2']['reference'])
          id = resolve_node_id(r['_id'])
          data_type = resolve_data_type(r['type'])

          refs.concat(reference(name, rel_type, id, target.name))

          if rel_type == 'HasProperty'
            nodes << variable_property(id, name,
                                       data_type, target.node_id,
                                       mandatory(r), node_id, @name)
          else
            nodes << component(id, name, target.node_id, target.name,
                               mandatory(r), rel_type, node_id, @name)
          end
        else
          puts "****** -> Cannot resolve type for #{target.name} #{r.inspect}"
        end
      end
    end
    [nodes, refs]
  end

  def generate_nodeset(root)
    return if stereotype_name == '<<Dynamic Type>>'

    if is_a_type?('BaseObjectType')
      node, refs = node('UAObjectType', node_id, @name, abstract: @abstract)
    elsif is_a_type?('BaseDataVariableType')
      # Need to add data type
      node, refs = node('UAVariableType', node_id, @name, abstract: @abstract, value_rank: -1)
    end


    if node
      puts "  -> Generating nodeset for #{@name}"
      root << node
      
      reference(@parent.name, 'HasSubtype', @parent.node_id, forward: false).
        each { |r| refs << r }
      
      nodes, references = attributes
      references.each { |r| refs << r }
      nodes.each { |n| root << n }

      nodes, references = relationships
      references.each { |r| refs << r }
      nodes.each { |n| root << n }
    end
  end
end
