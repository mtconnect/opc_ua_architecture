require 'type'
require 'bigdecimal'
require 'set'
require 'nodeset_relation'

XMLTypes = { 'Float' => 'xs:float',
             'Double' => 'xs:float',
             'String' => 'xs:string'
           }

class NodesetType < Type
  attr_reader :node_id

  class OwnerReference
    attr_reader :name, :node_id, :invariants
    def initialize(name, node_id, invariants)
      # puts "Creating Owner ref #{name} #{invariants.inspect}"
      @name, @node_id, @invariants = name, node_id, invariants
    end
  end
  
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
    check_ids
  end

  def browse_name
    is_opc? ? @name : "#{Namespace}:#{@name}"
  end
  
  def resolve_node_ids
    name = browse_name
    @node_id = NodesetModel.ids.id_for(name)
    @node_alias = @name if NodesetModel.ids.has_alias?(@name)

    unless is_opc?
      @relations.each { |r| r.resolve_node_ids(name) }
    else
      @relations.each { |r| r.create_name(name) }
    end
  end

  def node_alias
    @node_alias || @node_id
  end

  def node(type, id, name, display_name: nil, abstract: false, value_rank: nil, data_type: nil, symmetric: nil,
           prefix: true, parent: nil)
    node = REXML::Element.new(type)
    NodesetModel.root << node

    clean_name = name.sub(/\(.+$/, '')
    
    browse = prefix ? "#{Namespace}:#{clean_name}" : clean_name
    node.add_attributes({ 'NodeId' => id,
                          'BrowseName' => browse })
    node.add_attribute('IsAbstract', 'true') if abstract
    node.add_attribute('ValueRank', value_rank) if value_rank
    node.add_attribute('DataType', data_type) if data_type
    node.add_attribute('Symmetric', symmetric) unless symmetric.nil?
    node.add_attribute('ParentNodeId', parent) if parent

    node.add_element('DisplayName').add_text(display_name || clean_name)
    refs = node.add_element('References')
    
    [refs, node]
  end
  
  def node_reference(refs, name, type, target, target_type = nil, forward: true)
    refs << REXML::Comment.new(" #{type} - #{!forward ? '(Reverse)' : ''} - #{name} #{target} #{target_type}  ")
    ref = refs.add_element('Reference', { 'ReferenceType' => type })
    ref.add_attribute('IsForward', 'false') unless forward
    ref.add_text(target)
  end
  
  def reference(refs, rel, path = [], forward: true)
    node_reference(refs, rel.name, rel.reference_type_alias,
                   rel.node_id(path), rel.target.type.name,
                   forward: forward)

  rescue
    puts "#{$!}: #{rel.name}"
    raise $!
  end

  def add_value(ele, ref)
    value = ele.add_element('Value')
    resolved = ref.target.type.get_attribute_like('Value') || ref
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

  def variable_property(ref, owner, path = [])
    nid = ref.node_id(path)
    NodesetModel.ids.add_node_class(nid, ref.name, 'Variable', path)

    #puts " #{owner.name}::#{ref.name} : #{ref.target.type.name}[#{ref.multiplicity}] #{owner.class}"
    NodesetModel.root << REXML::Comment.new(" #{owner.name}::#{ref.name} : #{ref.target.type.name}[#{ref.multiplicity}] ")
    refs, ele = node('UAVariable', nid, ref.name, data_type: ref.target.type.node_alias,
                     value_rank: ref.value_rank, prefix: !is_opc_instance?, parent: owner.node_id)

    node_reference(refs, ref.target.type.name, 'HasTypeDefinition', ref.target_node_id, ref.target_node_name)
    node_reference(refs, ref.rule, 'HasModellingRule', NodesetModel.ids[ref.rule]) unless ref.type == 'uml:Slot'
    node_reference(refs, owner.name, 'HasProperty', owner.node_id, forward: false)

    # Add values for slots
    add_value(ele, ref) if ref.value and !ref.value.empty?

    # puts "#{ref.name}: #{owner.invariants.inspect} #{ref.target.type.name} default: #{ref.value}" if ref.value
    if owner.invariants and owner.invariants[ref.name]
      if ref.target.type.name == 'LocalizedText'
        value = ele.add_element('Value').
                  add_element('LocalizedText', { 'xmlns' => 'http://opcfoundation.org/UA/2008/02/Types.xsd' })
        value.add_element('Locale').add_text('en')
        value.add_element('Text').add_text(owner.invariants[ref.name])
      else
        raise "Do not know how to assign value for #{ref.target.type.name}"
      end
    end
    
  end

  def collect_references
    attrs = (@parent && @parent.collect_references) || {}
    @relations.select do |a|
      if !a.is_attribute? and a.name and
        (a.is_property? or a.is_a?(Relation::Association))
        attrs[a.name] = a
      end
    end
    attrs
  end

  def create_object_reference(refs, a)
    slot, = a.source.type.relations.select { |t| t.name == 'NodeId' }
    if slot
      nodeId = slot.value
    else
      nodeId = a.source.type.node_id
    end
    node_reference(refs, a.name, a.reference_type_alias,
                   nodeId, a.source.type.name,
                   forward: false)
  end

  def create_relationship(refs, a, owner, path)
    # puts "    Creating relationship #{a.name}"
    if a.is_property?
      reference(refs, a, path)
      variable_property(a, owner, path)
    elsif a.is_a? Relation::Association
      puts "++++ Creating relation #{a.name} #{a.final_target.type.node_class}"
      if a.final_target.type.node_class == 'Enumeration'
        values = NodesetModel.ids.id_for("#{a.final_target.type.browse_name}/#{a.name}")
        puts "+++++ Creating reference to #{a.final_target.type.browse_name}/#{a.name} #{values}"
        node_reference(refs, a.name, 'HasProperty', values,
                       "#{a.final_target.type.browse_name}/#{a.name}")
        
      else
        reference(refs, a, path)
        component(a, owner, path)
      end
    end
  end

  def instantiate_relations(refs, owner, path)
    attrs = collect_references
    attrs.each do |k, v|
      create_relationship(refs, v, owner, path)
    end
  end

  def component(ref, owner, path)
    nid = ref.node_id(path)    
    NodesetModel.root << REXML::Comment.new(" #{owner.name}::#{ref.name} : #{ref.target.type.name}[#{ref.multiplicity}] ")

    if ref.target.type.is_variable?
      NodesetModel.ids.add_node_class(nid, ref.name, 'Variable', path)
      refs, ele = node('UAVariable', nid, ref.name,
                       data_type: ref.target.type.variable_data_type.node_alias,
                       parent: owner.node_id)
    else
      NodesetModel.ids.add_node_class(nid, ref.name, 'Object', path)
      refs, ele = node('UAObject', nid, ref.name, parent: owner.node_id)
    end

    pnt = OwnerReference.new(ref.name, nid, ref.invariants)
    path = (path.dup << ref.name)
    ref.target.type.instantiate_relations(refs, pnt, path)

    node_reference(refs, ref.target.type.name, 'HasTypeDefinition', ref.target.type.node_id)
    node_reference(refs, ref.rule, 'HasModellingRule', NodesetModel.ids[ref.rule])
    node_reference(refs, owner.name, ref.reference_type, owner.node_id, forward: false)
  end

  def is_opc_instance?
    @type == 'uml:InstanceSpecification' and @classifier.is_opc?
  end
  
  def relationships(refs, owner, path = [])
    @relations.each do |a|
      if !a.is_attribute? and a.name
        puts "*** Relationship #{a.name} for #{owner.name}"
        create_relationship(refs, a, owner, path)
      elsif a.source.type.id != @id
        puts "*** Generate object reverse relation <<#{a.stereotype}>> #{@name}::#{a.name} -> #{a.source.type.name}"
        create_object_reference(refs, a)        
      elsif !a.is_attribute? 
        puts "!!! Cannot generate relation <<#{a.stereotype}>> #{@name}::#{a.name} #{a.source.type.name} -> #{a.final_target.type.name}"
      end
    end
  end

  def add_mixin_relations(refs, owner, path)
    # puts "---> Adding mixin relations: #{owner.name}"
    @parent.add_mixin_relations(refs, owner, path) if @parent
    relationships(refs, owner, path)
  end

  def node_class
    return '<DynamicType>' if stereotype_name == '<<Dynamic Type>>'

    if @type == 'uml:Enumeration'
      'Enumeration'
    elsif @type == 'uml:DataType'
      'DataType'
    elsif @type == 'uml:Object' or @type == 'uml:InstanceSpecification'
      'Object'
    elsif is_a_type?('BaseObjectType') or is_a_type?('BaseEventType')
      'ObjectType'
    elsif is_a_type?('BaseVariableType')
      'VariableType'
    elsif is_a_type?('References')
      'ReferenceType'
    elsif  @stereotype and @stereotype == 'mixin'
      'Mixin'
    elsif @stereotype and @stereotype == 'metaclass'
      'Metaclass'
    elsif @type == 'uml:Stereotype'
      'Stereotype'
    else
      puts "!! Do not know how to generate #{@name} #{@type} check Generalization Relationship"
      'Unknown'
    end
  end
  
  def generate_object_or_variable(nt)
    # puts "-> #{@name} -- #{nt}"
    
    case nt
    when 'ObjectType'
      NodesetModel.root << REXML::Comment.new(" Definition of Object #{@name} #{node_id} ")
      print "** Generating ObjectType #{@name} '#{node_id}'"
      NodesetModel.ids.add_node_class(node_id, @name, 'ObjectType')
      refs, = node('UAObjectType', node_id, @name, abstract: @abstract)

    when 'VariableType'
      v = get_attribute_like('ValueRank')
      NodesetModel.root << REXML::Comment.new(" Definition of Variable #{@name} #{node_id} ")
      print "** Generating VariableType"
      NodesetModel.ids.add_node_class(node_id, @name, 'VariableType')
      refs, = node('UAVariableType', node_id, @name, abstract: @abstract, value_rank: v.default,
                   data_type: variable_data_type.node_alias)

    when 'ReferenceType'
      NodesetModel.root << REXML::Comment.new(" Definition of Reference #{@name} #{node_id} ")
      print "** Generating ReferenceType"
      symmetric = get_attribute_like('Symmetric', /Attribute/)
      is_symmetric = symmetric.default
      NodesetModel.ids.add_node_class(node_id, @name, 'ReferenceType')
      refs, = node('UAReferenceType', node_id, @name, abstract: @abstract, symmetric: is_symmetric)
      
    else
      puts "-- Skipping #{nt} #{@name}"
    end
    
    if refs
      puts " for #{@name}"      
    
      node_reference(refs, @parent.name, 'HasSubtype', @parent.node_id, forward: false)

      @mixin.add_mixin_relations(refs, self, [browse_name]) if @mixin
      relationships(refs, self, [browse_name])
    end
  end

  def generate_enumeration
    puts "** Generating Enumeration for #{@name}"
    NodesetModel.root << REXML::Comment.new(" Definition of Enumeration #{@name} #{node_id} ")
    NodesetModel.ids.add_node_class(node_id, @name, 'DataType')
    refs, node = node('UADataType', node_id, @name)
    enum_nid = NodesetModel.ids.id_for("#{browse_name}/EnumStrings")
    
    node.add_element('Description').add_text(@documentation) if @documentation
    node_reference(refs, 'Enumeration', 'HasSubtype', NodesetModel.ids['Enumeration'], forward: false)
    node_reference(refs, 'EnumStrings', 'HasProperty', enum_nid)

    value_ele = REXML::Element.new('Value')
    values = value_ele.add_element('ListOfLocalizedText',
                                   { 'xmlns' => 'http://opcfoundation.org/UA/2008/02/Types.xsd'})

    # Create type dict entry
    struct = NodesetModel.type_dict_root.add_element('opc:EnumeratedType', {'Name' => @name,
                                                                            'LengthInBits' => '32',
                                                                            'BaseType' => "ua:ExtensionObject" })
    res = NodesetModel.xml_type_dict_root.add_element('xs:simpleType', {'name' => "#{@name}Enum" }).
            add_element('xs:restriction', { 'base' => 'xs:string' })
    
    defs = node.add_element('Definition', { 'Name' => @name })
    @literals.each do |name, value|
      field = defs.add_element('Field', { 'Name' => name, 'Value' => value })
      # field.add_element('Description').add_text(l['documentation']) if l['documentation']

      text = values.add_element('LocalizedText')
      text.add_element('Locale').add_text('en')
      text.add_element('Text').add_text(name)

      # For type dict
      struct.add_element('opc:EnumeratedValue', { 'Name' => name, 'Value' =>  value})
      res.add_element('xs:enumeration', { 'value' => name })
    end
    NodesetModel.xml_type_dict_root.add_element('xs:element', { 'name' => @name, 'type' => "mtc:#{@name}Enum" })
    
    # now create the enum strings property
    NodesetModel.root << REXML::Comment.new(" #{@name}::EnumStrings #{enum_nid} ")
    NodesetModel.ids.add_node_class(node_id, 'EnumStrings', 'Variable', [@name])
    refs, node = node('UAVariable', enum_nid, 'EnumStrings', data_type: 'LocalizedText',
                      value_rank: 1, parent: node_id)
    node_reference(refs, 'PropertyType', 'HasTypeDefinition', NodesetModel.ids['PropertyType'])
    node_reference(refs, 'Mandatory', 'HasModellingRule', NodesetModel.ids['Mandatory'])
    node_reference(refs, 'Owner', 'HasProperty', node_id, forward: false)

    node << value_ele

    # create_binary_encoding(struct)
    create_xml_encoding
  end

  def create_binary_encoding(frag)
    create_default_encoding('Binary', @name, frag)
  end

  def create_xml_encoding
    sel = "//xs:element[@name='#{@name}']"
    create_default_encoding('XML', sel)
  end

  def create_json_encoding
    create_default_encoding('JSON')
  end
  
  def create_default_encoding(encoding, sel = nil, frag = nil)
    # Generate Default encoding
    eid = NodesetModel.ids.id_for("#{browse_name}/Default #{encoding}")
    did = NodesetModel.ids.id_for("#{browse_name}/Default #{encoding}/Description") if sel
    fid = NodesetModel.ids.id_for("#{browse_name}/Default #{encoding}/Description/DictionaryFragment") if frag
    
    NodesetModel.root << REXML::Comment.new(" Default #{encoding} encoding of #{@name} ")
    erefs, enode = node('UAObject', eid, "Default #{encoding}", prefix: false)
    node_reference(erefs, @name, 'HasEncoding',  node_id, forward: false)
    node_reference(erefs, 'DataTypeEncodingType', 'HasTypeDefinition', NodesetModel.ids['DataTypeEncodingType'])
    
    if sel
      node_reference(erefs, 'HasDescription', 'HasDescription', did)

      schema = NodesetModel.ids["#{Namespace}:Opc.Ua.MTConnect(#{encoding})"]

      NodesetModel.root << REXML::Comment.new(" #{encoding} DataTypeDescription for #{@name} ")
      drefs, dnode = node('UAVariable', did, @name, data_type: 'String', parent: schema)
      node_reference(drefs, 'DataTypeDescriptionType', 'HasTypeDefinition', NodesetModel.ids['DataTypeDescriptionType'])
      node_reference(drefs, 'DictionaryFragment', 'HasProperty', fid) if frag
      node_reference(drefs, 'Opc.Ua.MTConnect', 'HasComponent', schema, forward: false)
      
      dnode.add_element('Value').add_element('String',
                                             {'xmlns' => 'http://opcfoundation.org/UA/2008/02/Types.xsd'}).
        add_text(sel)
      
      # add a reference
      obj = Type.type_for_name("Opc.Ua.MTConnect(#{encoding})")
      obj.add_component_ref(@name, did)    
    
      if frag
        NodesetModel.root << REXML::Comment.new(" DictionaryFragment for #{@name} ")
        frefs, fnode = node('UAVariable', fid, "DictionaryFragment", data_type: 'ByteString', parent: did)
        node_reference(frefs, 'Owner', 'HasProperty', did, forward: false)
        node_reference(frefs, 'PropertyType', 'HasTypeDefinition', NodesetModel.ids['PropertyType'])
        
        formatter = REXML::Formatters::Pretty.new(2)
        formatter.compact = true
        text = ""
        formatter.write(frag, text)
        # puts "******* #{@name} Fragment"
        # puts text
        
        value = fnode.add_element('Value').add_element('ByteString',
                                                       {'xmlns' => 'http://opcfoundation.org/UA/2008/02/Types.xsd'})
        value << REXML::CData.new([text].pack('m'), true)      
      end
    end
  end

  def add_component_ref(name, id)
    # puts "Adding refs for #{@name} -> #{name}"
    node_reference(@refs, name, 'HasComponent', id)
  end

  def generate_data_type
    puts "** Generating DataType for #{@name}"
    NodesetModel.ids.add_node_class(node_id, @name, 'DataType')
    NodesetModel.root << REXML::Comment.new(" Definition of DataType #{@name} #{node_id} ")
    @refs, node = node('UADataType', node_id, @name)
    node.add_element('Description').add_text(@documentation) if @documentation
    node_reference(@refs, 'BaseDataType', 'HasSubtype', NodesetModel.ids['Structure'], forward: false)
    
    defs = node.add_element('Definition', { 'Name' => @name })
    @relations.each do |r|
      field = defs.add_element('Field', { 'Name' => r.name, 'DataType' =>  r.target.type.node_alias })
      if r.is_array?
        field.add_attribute("ValueRank", "1")
      end
      if r.is_optional?
        field.add_attribute("IsOptional", "true")
      end
      field.add_element('Description').add_text(r.documentation) if r.documentation
    end

    # Create entry in TypeDictionary
    struct = NodesetModel.type_dict_root.add_element('opc:StructuredType', {'Name' => @name, 'BaseType' => "ua:ExtensionObject" })
    struct.add_element('opc:Documentation').add_text("The encoding for #{@name}")

    seq = NodesetModel.xml_type_dict_root.add_element('xs:complexType', {'name' => "#{@name}DataType" }).
            add_element('xs:sequence')
    
    @relations.each do |r|
      struct.add_element('opc:Field', { 'Name' => r.name, 'TypeName' =>  "opc:#{r.target.type.name}" })
      seq.add_element('xs:element', { 'name' => r.name,
                                      'type' => XMLTypes[r.target.type.name],
                                      'minOccurs' => '1', 'maxOccurs' => '1' })
    end
    NodesetModel.xml_type_dict_root.add_element('xs:element', { 'name' => @name, 'type' => "mtc:#{@name}DataType"})

    create_binary_encoding(struct)
    create_xml_encoding
    create_json_encoding
  end

  def generate_instance
    print "++ Generating #{@classifier.base_type} #{@name}"
    NodesetModel.root << REXML::Comment.new(" Instantiation of Object #{@name} #{node_id} ")
    if @classifier.base_type == 'Variable'
      puts "::#{@classifier.name} - #{@classifier.variable_data_type.name}"
      NodesetModel.ids.add_node_class(node_id, @name, 'Variable')
      @refs, @node = node('UAVariable', node_id, @name, data_type: @classifier.variable_data_type.node_alias)
    else
      puts "::#{@classifier.name}"
      NodesetModel.ids.add_node_class(node_id, @name, 'Object')
      @refs, @node = node('UAObject', node_id, @name)
    end
    node_reference(@refs, @classifier.name, 'HasTypeDefinition', @classifier.node_id)

    relationships(@refs, self, [browse_name])
  end

  def add_base64_value(text)
    if @node
      e = @node.add_element('Value').
        add_element('ByteString', { 'xmlns' => "http://opcfoundation.org/UA/2008/02/Types.xsd"})
      e << REXML::CData.new([text].pack('m'), true)
    else
      puts "!!!! Cannot add text to node"
      raise "Error generating text"
    end
  end


  def generate_nodeset
    return if stereotype_name == '<<Dynamic Type>>'

    nt = node_class
    case nt
    when 'Enumeration'
      generate_enumeration
    when 'DataType'
      generate_data_type
    when 'Object'
      generate_instance
    when 'Metaclass'
      puts "Skipping metaclass #{@name}"
    else
      generate_object_or_variable(nt)
    end
  end
end


