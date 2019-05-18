require 'rexml/document'
require 'nokogiri'
require 'nodeset_model.rb'
require 'nodeset_type.rb'

Namespace = '1'
NamespaceUri = 'http://opcfoundation.org/UA/MTConnect/v2/'

formatter = REXML::Formatters::Pretty.new(2)
formatter.compact = true

RSpec.describe NodesetModel, 'SimpleType Nodeset definitions' do
  before(:all) do
    Type.clear
    Model.clear
    Relation.clear

    id_file = File.join(File.dirname(__FILE__), 'scratch', 'SimpleType.csv')
    opc_file = File.join(File.dirname(__FILE__), 'scratch', 'SimpleType.NodeIds.csv')
    NodesetModel.create_id_manager(id_file, opc_file, true)
    
    @xmiDoc = @rootModel = nil
    File.open(File.join(File.dirname(__FILE__), 'fixtures', 'SimpleType.xmi')) do |xmi|
      @xmiDoc = Nokogiri::XML(xmi).slop!
      @xmiDoc.remove_namespaces!
      @rootModel = @xmiDoc.at('//packagedElement[@type="uml:Package" and @name="Model"]')
    end

    NodesetModel.new(@rootModel).find_definitions
    NodesetType.resolve_node_ids
  end

  before(:each) do
    NodesetModel.nodeset_document
    NodesetModel.type_dict_document
    NodesetModel.xml_type_dict_document    
  end

  context 'with Id Manager' do
    before(:each) do
      @ids = NodesetModel.ids
    end
    
    it 'should initialize id manager from OpcUA aliases' do
      expect(@ids.has_alias?('String')).to be true
      expect(@ids['String']).to eq('String')
      expect(@ids['GeneratesEvent']).to eq('i=41')
      expect(@ids.has_alias?('GeneratesEvent')).to be false
    end
  end

  context 'with ComponentType' do
    before(:each) do
      @type = NodesetType.type_for_name('ComponentType')
    end

    it 'should have a ComponentType' do
      expect(@type).to_not be_nil
    end

    it 'should generate xml' do
      @type.generate_nodeset
      formatter.write(NodesetModel.document, STDOUT)
    end
  end

end

RSpec.describe NodesetModel, 'MixinType Nodeset definitions' do
  before(:all) do
    Type.clear
    Model.clear
    Relation.clear

    id_file = File.join(File.dirname(__FILE__), 'scratch', 'MixinType.csv')
    opc_file = File.join(File.dirname(__FILE__), 'scratch', 'MixinType.NodeIds.csv')
    NodesetModel.create_id_manager(id_file, opc_file, true)
    
    @xmiDoc = @rootModel = nil
    File.open(File.join(File.dirname(__FILE__), 'fixtures', 'MixinType.xmi')) do |xmi|
      @xmiDoc = Nokogiri::XML(xmi).slop!
      @xmiDoc.remove_namespaces!
      @rootModel = @xmiDoc.at('//packagedElement[@type="uml:Package" and @name="Model"]')
    end

    NodesetModel.new(@rootModel).find_definitions
    NodesetType.resolve_node_ids
  end

  before(:each) do
    NodesetModel.nodeset_document
    NodesetModel.type_dict_document
    NodesetModel.xml_type_dict_document    
  end

  context 'with Id Manager' do
    before(:each) do
      @ids = NodesetModel.ids
    end
    
    it 'should initialize id manager from OpcUA aliases' do
      expect(@ids.has_alias?('String')).to be true
      expect(@ids['String']).to eq('String')
      expect(@ids['GeneratesEvent']).to eq('i=41')
      expect(@ids.has_alias?('GeneratesEvent')).to be false
    end
  end

  context 'with ComponentType' do
    before(:each) do
      @type = NodesetType.type_for_name('ComponentType')
    end

    it 'should have a ComponentType' do
      expect(@type).to_not be_nil
    end

    it 'should generate xml' do
      @type.generate_nodeset
      formatter.write(NodesetModel.document, STDOUT)
    end
  end

  context 'with Compositions' do
    before(:each) do
      @type = NodesetType.type_for_name('CompositionType')
    end

    it 'should have a CompositionType' do
      expect(@type).to_not be_nil
    end

    it 'should generate xml' do
      @type.generate_nodeset
      formatter.write(NodesetModel.document, STDOUT)
    end
  end

  context 'with CompositionFolder' do
    before(:each) do
      @type = NodesetType.type_for_name('CompositionFolder')
    end

    it 'should have a CompositionFolder' do
      expect(@type).to_not be_nil
    end

    it 'should generate xml' do
      @type.generate_nodeset
      formatter.write(NodesetModel.document, STDOUT)
    end
  end

  context 'with NamespaceMetadata Object' do
    before(:each) do
      @object = Type.type_for_name('http://opcfoundation.org/UA/MTConnect/2.0/')
    end

    it 'should have a metadata object' do
      expect(@object).to_not be_nil
      expect(@object.relations.count).to eq(7)
      nodeIdTypes = @object.relation('StaticNodeIdTypes')
      expect(nodeIdTypes.is_array?).to be true
      expect(nodeIdTypes.value).to eq('[0]')
      expect(@object.relation('StaticNumericNodeIdRange').value).to eq('[1:1073741824]')
    end

    it 'should generate xml' do
      @object.generate_nodeset
      formatter.write(NodesetModel.document, STDOUT)
    end
  end
end

