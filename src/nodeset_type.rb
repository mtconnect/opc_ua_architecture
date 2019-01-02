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
    attr_reader :name, :node_id, :tags
    def initialize(name, node_id, tags)
      @name, @node_id, @tags = name, node_id, tags
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
  end

  def browse_name
    is_opc? ? @name : "#{Namespace}:#{@name}"
  end
  
  def resolve_node_ids
    name = browse_name
    @node_id = Ids.id_for(name)
    @node_alias = @name if Ids.has_alias?(@name)

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
    Root << node

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
    ref = REXML::Element.new('Reference')
    ref = refs.add_element('Reference', { 'ReferenceType' => type })
    ref.add_attribute('IsForward', 'false') unless forward
    ref.add_text(target)
  end
  
  def reference(refs, rel, path = [], forward: true)
    node_reference(refs, rel.name, rel.reference_type_alias,
                   rel.node_id(path), rel.target.type.name,
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

  def variable_property(ref, owner, path = [])
    Root << REXML::Comment.new(" #{owner.name}::#{ref.name} : #{ref.target.type.name}[#{ref.multiplicity}] ")
    refs, ele = node('UAVariable', ref.node_id(path), ref.name, data_type: ref.target.type.node_alias,
                     value_rank: ref.value_rank, prefix: !is_opc_instance?, parent: owner.node_id)
    node_reference(refs, ref.target.type.name, 'HasTypeDefinition', ref.target_node_id, ref.target_node_name)
    node_reference(refs, ref.rule, 'HasModellingRule', Ids[ref.rule]) unless ref.type == 'UMLSlot'
    node_reference(refs, owner.name, 'HasProperty', owner.node_id, forward: false)

    # Add values for slots
    add_value(ele, ref) if ref.type == 'UMLSlot'

    if owner.tags
      tag, = owner.tags.select { |t| t['name'] == ref.name }
      if tag
        if ref.target.type.name == 'LocalizedText'
          value = ele.add_element('Value').
                    add_element('LocalizedText', { 'xmlns' => 'http://opcfoundation.org/UA/2008/02/Types.xsd' })
          value.add_element('Locale').add_text('en')
          value.add_element('Text').add_text(tag['value'])
        else
          raise "Do not know how to assign value for #{ref.target.type.name}"
        end
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

  def create_opc_object_reference(refs, a)
    slot, = a.target.type.relations.select { |t| t.name == 'NodeId' }
    if slot
      nodeId = slot.value
    else
      nodeId = a.target.type.node_id
    end
    node_reference(refs, a.name, a.reference_type_alias,
                   nodeId, a.target.type.name,
                   forward: a.target.navigable)
  end

  def create_relationship(refs, a, owner, path)
    #puts "    Creating relationship"
    if a.is_property?
      reference(refs, a, path)
      variable_property(a, owner, path)
    elsif a.is_a? Relation::Association
      #puts "      Checking OPC object ref"
      if @type == 'UMLObject' && a.target.type.is_opc?
        create_opc_object_reference(refs, a)
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
    Root << REXML::Comment.new(" #{owner.name}::#{ref.name} : #{ref.target.type.name}[#{ref.multiplicity}] ")
    if ref.target.type.is_variable?
      refs, ele = node('UAVariable', nid, ref.name,
                       data_type: ref.target.type.variable_data_type.node_alias,
                       parent: owner.node_id)
    else
      refs, ele = node('UAObject', nid, ref.name, parent: owner.node_id)
    end

    pnt = OwnerReference.new(ref.name, nid, ref.tags)
    path = (path.dup << browse_name)
    ref.target.type.instantiate_relations(refs, pnt, path)

    node_reference(refs, ref.target.type.name, 'HasTypeDefinition', ref.target.type.node_id)
    node_reference(refs, ref.rule, 'HasModellingRule', Ids[ref.rule])
    node_reference(refs, owner.name, ref.reference_type, owner.node_id, forward: false)
  end

  def is_opc_instance?
    @type == 'UMLObject' and @classifier.is_opc?
  end
  
  def relationships(refs, owner, path = [])
    @relations.each do |a|
      if !a.is_attribute? and a.name
        create_relationship(refs, a, owner, path)
      end
    end
  end

  def add_mixin_relations(refs, owner, path)
    @parent.add_mixin_relations(refs, owner, path) if @parent
    relationships(refs, owner, path)
  end

  def generate_object_or_variable
    if is_a_type?('BaseObjectType') or is_a_type?('BaseEventType')
      Root << REXML::Comment.new(" Definition of Object #{@name} #{node_id} ")
      puts "      ** Generating ObjectType"
      refs, = node('UAObjectType', node_id, @name, abstract: @abstract)
    elsif is_a_type?('BaseVariableType')
      v = get_attribute_like(/ValueRank$/)
      Root << REXML::Comment.new(" Definition of Variable #{@name} #{node_id} ")
      puts "      ** Generating VariableType"
      refs, = node('UAVariableType', node_id, @name, abstract: @abstract, value_rank: v.default,
                        data_type: variable_data_type.node_alias)
    elsif is_a_type?('References')
      Root << REXML::Comment.new(" Definition of Reference #{@name} #{node_id} ")
      symmetric = get_attribute_like(/Symmetric$/, /Attribute/)
      is_symmetric = symmetric.default
      refs, = node('UAReferenceType', node_id, @name, abstract: @abstract, symmetric: is_symmetric)
    elsif  @stereotype and @stereotype.name == 'mixin'
      puts "** Skipping mixin #{@name}"
    else
      puts "!! Do not know how to generate #{@name} #{@type} check Generalization Relationship"
    end
    
    if refs
      puts "  -> Generating nodeset for #{@name}"      
    
      node_reference(refs, @parent.name, 'HasSubtype', @parent.node_id, forward: false)
      
      @mixin.add_mixin_relations(refs, self, [browse_name]) if @mixin
      relationships(refs, self)
    end
  end

  def generate_enumeration
    puts "  => Enumeration #{@name} #{@id}"
    Root << REXML::Comment.new(" Definition of Enumeration #{@name} #{node_id} ")
    refs, node = node('UADataType', node_id, @name)
    enum_nid = Ids.id_for("#{browse_name}/EnumStrings")
    
    # node.add_element('Description').add_text(@documentation) if @documentation
    node_reference(refs, 'Enumeration', 'HasSubtype', Ids['Enumeration'], forward: false)
    node_reference(refs, 'EnumStrings', 'HasProperty', enum_nid)

    value_ele = REXML::Element.new('Value')
    values = value_ele.add_element('ListOfLocalizedText',
                                   { 'xmlns' => 'http://opcfoundation.org/UA/2008/02/Types.xsd'})

    # Create type dict entry
    struct = TypeDictRoot.add_element('opc:EnumeratedType', {'Name' => @name, 'LengthInBits' => '32', 'BaseType' => "ua:ExtensionObject" })
    res = XmlTypeDictRoot.add_element('xs:simpleType', {'name' => @name }).
            add_element('xs:restriction', { 'base' => 'xs:string' })
    
    defs = node.add_element('Definition', { 'Name' => @name })
    @literals.each do |l|
      name, value = l['name'].split('=')
      field = defs.add_element('Field', { 'Name' => name, 'Value' => value })
      field.add_element('Description').add_text(l['documentation']) if l['documentation']

      text = values.add_element('LocalizedText')
      text.add_element('Locale').add_text('en')
      text.add_element('Text').add_text(name)

      # For type dict
      struct.add_element('opc:EnumeratedValue', { 'Name' => name, 'Value' =>  value})
      res.add_element('xs:enumeration', { 'value' => name })
    end
    XmlTypeDictRoot.add_element('xs:element', { 'name' => @name, 'type' => "mtc:#{@name}" })
    
    # now create the enum strings property
    Root << REXML::Comment.new(" #{@name}::EnumStrings #{enum_nid} ")
    refs, node = node('UAVariable', enum_nid, 'EnumStrings', data_type: 'LocalizedText',
                      value_rank: 1, parent: node_id)
    node_reference(refs, 'PropertyType', 'HasTypeDefinition', Ids['PropertyType'])
    node_reference(refs, 'Mandatory', 'HasModellingRule', Ids['Mandatory'])
    node_reference(refs, 'Owner', 'HasProperty', node_id, forward: false)

    node << value_ele

    create_binary_encoding(struct)
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
    eid = Ids.id_for("#{browse_name}/Default #{encoding}")
    did = Ids.id_for("#{browse_name}/Default #{encoding}/Description") if sel
    fid = Ids.id_for("#{browse_name}/Default #{encoding}/Description/DictionaryFragment") if frag
    
    Root << REXML::Comment.new(" Default #{encoding} encoding of #{@name} ")
    erefs, enode = node('UAObject', eid, "Default #{encoding}", prefix: false)
    node_reference(erefs, @name, 'HasEncoding',  node_id, forward: false)
    node_reference(erefs, 'DataTypeEncodingType', 'HasTypeDefinition', Ids['DataTypeEncodingType'])
    
    if sel
      node_reference(erefs, 'HasDescription', 'HasDescription', did)

      schema = Ids["#{Namespace}:Opc.Ua.MTConnect.#{encoding}"]

      Root << REXML::Comment.new(" #{encoding} DataTypeDescription for #{@name} ")
      drefs, dnode = node('UAVariable', did, @name, data_type: 'String', parent: schema)
      node_reference(drefs, 'DataTypeDescriptionType', 'HasTypeDefinition', Ids['DataTypeDescriptionType'])
      node_reference(drefs, 'DictionaryFragment', 'HasProperty', fid) if frag
      node_reference(drefs, 'Opc.Ua.MTConnect', 'HasComponent', schema, forward: false)
      
      dnode.add_element('Value').add_element('String',
                                             {'xmlns' => 'http://opcfoundation.org/UA/2008/02/Types.xsd'}).
        add_text(sel)
      
      # add a reference
      obj = Type.type_for_name("Opc.Ua.MTConnect(#{encoding})")
      obj.add_component_ref(@name, did)    
    
      if frag
        Root << REXML::Comment.new(" DictionaryFragment for #{@name} ")
        frefs, fnode = node('UAVariable', fid, "DictionaryFragment", data_type: 'ByteString', parent: did)
        node_reference(frefs, 'Owner', 'HasProperty', did, forward: false)
        node_reference(frefs, 'PropertyType', 'HasTypeDefinition', Ids['PropertyType'])
        
        formatter = REXML::Formatters::Pretty.new(2)
        formatter.compact = true
        text = ""
        formatter.write(frag, text)
        puts "******* #{@name} Fragment"
        puts text
        
        value = fnode.add_element('Value').add_element('ByteString',
                                                       {'xmlns' => 'http://opcfoundation.org/UA/2008/02/Types.xsd'})
        value << REXML::CData.new([text].pack('m'), true)      
      end
    end
  end

  def add_component_ref(name, id)
    node_reference(@refs, name, 'HasComponent', id)
  end

  def generate_data_type
    puts "  => DataType #{@name}"
    Root << REXML::Comment.new(" Definition of DataType #{@name} #{node_id} ")
    refs, node = node('UADataType', node_id, @name)
    #node.add_element('Description').add_text(@documentation) if @documentation
    node_reference(refs, 'BaseDataType', 'HasSubtype', Ids['Structure'], forward: false)
    
    defs = node.add_element('Definition', { 'Name' => @name })
    @relations.each do |r|
      field = defs.add_element('Field', { 'Name' => r.name, 'DataType' =>  r.target.type.node_alias })
      if r.multiplicity =~ /..\*$/
        field.add_attribute("ValueRank", "1")
      end
      field.add_element('Description').add_text(r.documentation) if r.documentation
    end

    # Create entry in TypeDictionary
    struct = TypeDictRoot.add_element('opc:StructuredType', {'Name' => @name, 'BaseType' => "ua:ExtensionObject" })
    struct.add_element('Documentation').add_text("The encoding for #{@name}")

    seq = XmlTypeDictRoot.add_element('xs:complexType', {'name' => @name }).
            add_element('xs:sequence')
    
    @relations.each do |r|
      struct.add_element('opc:Field', { 'Name' => r.name, 'TypeName' =>  "opc:#{r.target.type.name}" })
      seq.add_element('xs:element', { 'name' => r.name,
                                      'type' => XMLTypes[r.target.type.name],
                                      'minOccurs' => '1', 'maxOccurs' => '1' })
    end
    XmlTypeDictRoot.add_element('xs:element', { 'name' => @name, 'type' => "mtc:#{@name}"})

    create_binary_encoding(struct)
    create_xml_encoding
    create_json_encoding
  end

  def generate_instance    
    puts "  => #{@classifier.base_type} #{@name}"
    Root << REXML::Comment.new(" Instantiation of Object #{@name} #{node_id} ")
    if (@classifier.base_type == 'Variable')
      puts "    - #{@classifier.variable_data_type.name}"
      @refs, @node = node('UAVariable', node_id, @name, data_type: @classifier.variable_data_type.node_alias)
    else
      @refs, @node = node('UAObject', node_id, @name)
    end
    node_reference(@refs, @classifier.name, 'HasTypeDefinition', @classifier.node_id)

    path = []
    relationships(@refs, self, path)
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

    if @type == 'UMLEnumeration'
      generate_enumeration
    elsif @type == 'UMLDataType'
      generate_data_type
    elsif @type == 'UMLObject'
      generate_instance
    else
      generate_object_or_variable
    end
  end
end


