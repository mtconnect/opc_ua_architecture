require 'rexml/document'
require 'nokogiri'
require 'nodeset_model.rb'
require 'nodeset_type.rb'

Namespace = '1'
NamespaceUri = 'http://opcfoundation.org/UA/MTConnect/v2/'

formatter = REXML::Formatters::Pretty.new(2)
formatter.compact = true

RSpec.describe NodesetModel, 'SimpleType definitions' do
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
