
require 'rexml/document'
require 'nokogiri'
require 'latex_model.rb'

RSpec.describe LatexModel, 'SimpleType definitions' do
  before(:all) do
    Type.clear
    Model.clear
    Relation.clear
    
    @xmiDoc = @rootModel = nil
    File.open(File.join(File.dirname(__FILE__), 'fixtures', 'SimpleType.xmi')) do |xmi|
      @xmiDoc = Nokogiri::XML(xmi).slop!
      @xmiDoc.remove_namespaces!
      @rootModel = @xmiDoc.at('//packagedElement[@type="uml:Package" and @name="Model"]')
    end

    LatexModel.new(@rootModel).find_definitions
  end
  
  context 'with xml loaded' do
    it 'should load package root' do
      expect(@rootModel['name']).to eq('Model')
      expect(@rootModel['id']).to eq('EAPK_1AE52DA8_3C11_4343_BE30_25D038866667')
    end

    it 'should create models for the packages' do
      # Do some simple model level checks
      expect(Model.models.length).to eq(9)
      expect(Model.models['SimpleType']).to_not be_nil
      expect(Model.models['OPC UA Part 05']).to_not be_nil
      expect(Model.models['SimpleType'].is_opc?).to be false
    end
      

    context 'when models are loaded' do
      before(:example) do
        @package = Model.models['SimpleType']        
      end
      
      it 'should have a ComponentType class' do
        expect(@package.types.length).to eq(2)
        type = @package.types.first
        expect(type.name).to eq('ComponentType')
        expect(type.id).to eq('EAID_7607130B_07BB_44fd_8ECA_1A16A2E28B37')
        expect(type.type).to eq('uml:Class')
      end
      
      context 'with a ComponentType' do
        before(:example) do
          @component = @package.types.first
        end
        
        it 'should have a generalization to BasicObject' do
          parent = @component.get_parent
          expect(parent).to_not be_nil
          expect(parent.name).to eq('BaseObjectType')
        end
        
        it 'should have a relationship as a folder' do
          expect(@component.relations.length).to eq(5)
          comp, = @component.relations.select { |r| r.name == 'Compositions' }
          expect(comp).to_not be_nil
          expect(comp.is_folder?).to be true
        end
        
        it 'should have an optional Compositions folder' do
          comp, = @component.relations.select { |r| r.name == 'Compositions' }
          expect(comp.is_optional?).to be true
        end
        
        it 'should have the far side of the composition relation should be a compostion type' do
          expect(@component.relations.length).to eq(5)
          comp, = @component.relations.select { |r| r.name == 'Compositions' }
          expect(comp.source.type.name).to eq('ComponentType')
          expect(comp.target.name).to eq('OrganizedBy')
          expect(comp.target.type.name).to eq('FolderType')
          expect(comp.final_target.type.name).to eq('CompositionType')
        end

        it 'should have documentation' do
          expect(@component.documentation).to_not be_nil
          fname = File.join(File.dirname(__FILE__), 'fixtures', 'ComponentDocs.tex')
          #File.open(fname, 'w') do |f|
          #  f.write @component.documentation
          #end

          expect(@component.documentation).to eq(File.read(fname))
        end
      end
    end
  end

  context 'with file output' do
    before(:each) do
      @output = StringIO.new
    end

    it 'should generate latex' do
      LatexModel.generate_latex(@output, 'SimpleType')
      fname = File.join(File.dirname(__FILE__), 'fixtures', 'SimpleType.tex')
      #File.open(fname, 'w') do |f|
      #  f.write @output.string
      #end

      expect(@output.string).to eq(File.read(fname))
    end
  end
end

RSpec.describe LatexModel, 'MixinType definitions' do
  before(:all) do
    Type.clear
    Model.clear
    Relation.clear
    
    @xmiDoc = @rootModel = nil
    File.open(File.join(File.dirname(__FILE__), 'fixtures', 'MixinType.xmi')) do |xmi|
      @xmiDoc = Nokogiri::XML(xmi).slop!
      @xmiDoc.remove_namespaces!
      @rootModel = @xmiDoc.at('//packagedElement[@type="uml:Package" and @name="Model"]')
    end

    LatexModel.new(@rootModel).find_definitions
  end

  context 'when models are loaded' do
    before(:example) do
      @package = Model.models['MixinType']        
    end

    it 'should be have the mixin package' do
      expect(@package).to_not be_nil
    end

    it 'should have an IntegerEventType' do
      expect(Type.type_for_name('IntegerEventType')).to_not be_nil
    end

    context 'with IntegerEventType' do
      before(:example) do
        @type = Type.type_for_name('IntegerEventType')
      end

      it 'should have a realization that is a mixin' do
        expect(@type.realizations.length).to eq(1)
        real = @type.realizations.first
        expect(real.is_mixin?).to be true
        expect(real.name).to eq('Mixes In')
        expect(real.target.type.name).to eq('DataItemMixin')
      end

      it 'should have a value rank of -1' do
        expect(@type.relation('ValueRank').default).to eq('-1')
      end

      it 'should have documentation associated with the Generalization' do
        expect(@type.relation('Supertype').documentation).to eq('For EVENT with Integer')
      end
    end

    context 'with a ThreeSpaceSampleType' do
      before(:example) do
        @type = Type.type_for_name('ThreeSpaceSampleType')
      end

      it 'should have a ThreeSpace data type' do
        @type.relations.map { |e| e.name }
        attr = @type.relation('DataType')
        expect(attr).to_not be_nil
        expect(attr.target.type.name).to eq('ThreeSpace')
      end
    end

    context 'with CompositionType' do
      before(:example) do
        @type = Type.type_for_name('CompositionType')
      end

      it 'should have values EnumStrings linked to Vocab enumeration' do
        s, = @type.relation('EnumStrings')
        expect(s).to_not be_nil
        expect(s.name).to eq('EnumStrings')
        expect(s.target.type.name).to eq('Vocab')
        expect(s.target.type.literals).to eq([["CAT", "0"], ["DOG", "1"], ["HORSE", "2"]])
      end
    end

    context 'with ComponentType' do
      before(:example) do
        @type = Type.type_for_name('ComponentType')
      end

      it 'should have a property uuid with documentation' do
        expect(@type.relation('uuid').documentation).to eq('Only required with Device')
      end

      it 'should have a relation, ActiveState, with two invariants' do
        as = @type.relation('ActiveState')
        expect(as).to_not be_nil

        expect(as.invariants['FalseState']).to eq('Inactive')
        expect(as.invariants['TrueState']).to eq('Active')        
      end      
    end
    
  end  

  it 'should generate latex' do
    output = StringIO.new
    LatexModel.generate_latex(output, 'MixinType')
    fname = File.join(File.dirname(__FILE__), 'fixtures', 'MixinType.tex')
    #File.open(fname, 'w') do |f|
    #  f.write output.string
    #end
    
    expect(output.string).to eq(File.read(fname))
  end
end
