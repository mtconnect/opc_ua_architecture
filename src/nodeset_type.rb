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

  def generate_nodeset(root)
    return if stereotype_name == '<<Dynamic Type>>'

    if is_a_type?('BaseObjectType')
      obj = root.add_element('UAObjectType',
                             { 'NodeId' => node_id,
                               'BrowseName' => "1:#{@name}",
                               'IsAbstract' => @abstract.to_s})
    elsif is_a_type?('BaseDataVariableType')
      obj = root.add_element('UAVariableType',
                             { 'NodeId' => node_id,
                               'BrowseName' => "1:#{@name}",
                               'ValueRank' => '-1' })
    end

    if obj
      puts "  -> Generating nodeset for #{@name}"
      obj.add_element('DisplayName').add_text(@name)
      
      refs = obj.add_element('References')
      parent_id = @parent.node_id
      refs << REXML::Comment.new(@parent.name)
      refs.add_element('Reference', { 'ReferenceType' => 'HasSubtype',
                                      'IsForward' => 'false' }).
        add_text(parent_id)

      generate_references(refs)

      generate_variables(root)
      generate_components(root)
    end
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
  
  def generate_references(refs)
    @attributes.each do |a|
      stereo = a['stereotype'] && resolve_type_name(a['stereotype'])
      unless stereo =~ /Attribute/
        refs << REXML::Comment.new(a['name'])
        refs.add_element('Reference', { 'ReferenceType' => 'HasProperty' }).
          add_text(resolve_node_id(a['_id']))
      end
    end
    @relations.each do |r|
      if r['_type'] == 'UMLAssociation'
        target = resolve_type(r['end2']['reference'])

        if target and (r['name'] or r['end1']['name'])
          stereo = relation_type(r)
          name = r['end1']['name'] || r['name']
          
          refs << REXML::Comment.new("Relation #{name} - #{stereo} -> #{target.name}")
          refs.add_element('Reference', { 'ReferenceType' => stereo }).
            add_text(resolve_node_id(r['_id']))
        else
          puts "******* Cannot resolve type for #{r['name']}"
        end
      end
    end
  end

  def resolve_data_type(type)
    return type if Aliases.include?(type)
    NodeIds[type]
  end

  def generate_variables(root)
    @attributes.each do |a|
      # TODO Resolve Type from aliases or type reference to our own types.
      # Log error if type cannot be resolved.
      stereo = a['stereotype'] && resolve_type_name(a['stereotype'])
      unless stereo =~ /Attribute/
        var = root.add_element('UAVariable', {
                                 'NodeId' => resolve_node_id(a['_id']),
                                 'BrowseName' => "1:#{a['name']}",
                                 'DataType' => resolve_data_type(a['type']) })
        var.add_element('DisplayName').add_text(a['name'])
        refs = var.add_element('References')
        refs.add_element('Reference', { 'ReferenceType' => 'HasTypeDefinition' }).
          add_text(NodeIds['PropertyType'])
        refs << REXML::Comment.new(mandatory(a))
        refs.add_element('Reference', { 'ReferenceType' => 'HasModelingRule' }).
          add_text(NodeIds[mandatory(a)])
        refs << REXML::Comment.new(@name)
        refs.add_element('Reference', { 'ReferenceType' => 'HasProperty', 'IsForward' => 'false' }).
          add_text(node_id)
      end
    end
  end
  
  def generate_components(root)
    @relations.each do |a|
      if a['_type'] == 'UMLAssociation' and
        (name = (a['name'] or a['end1']['name']))

        target = resolve_type(a['end2']['reference'])
        
        stereo = relation_type(a)
        var = root.add_element('UAVariable', {
                                 'NodeId' => resolve_node_id(a['_id']),
                                 'BrowseName' => "1:#{name}",
                                 'DataType' => resolve_data_type(a['type']) })
        var.add_element('DisplayName').add_text(name)
        refs = var.add_element('References')
        refs.add_element('Reference', { 'ReferenceType' => 'HasTypeDefinition' }).
          add_text(NodeIds['PropertyType'])
        refs << REXML::Comment.new(mandatory(a))
        refs.add_element('Reference', { 'ReferenceType' => 'HasModelingRule' }).
          add_text(NodeIds[mandatory(a)])
        refs << REXML::Comment.new(@name)
        refs.add_element('Reference', { 'ReferenceType' => stereo, 'IsForward' => 'false' }).
          add_text(node_id)
      end
    end
  end
end
