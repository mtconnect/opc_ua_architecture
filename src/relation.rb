module Relation
  def self.create_association(owner, r)
    case r['_type']
    when 'UMLGeneralization'
      Generalization.new(owner, r)

    when 'UMLRealization'
      Realization.new(owner, r)

    when 'UMLDependency'
      Dependency.new(owner, r)

    when 'UMLAttribute'
      Attribute.new(owner, r)

    when 'UMLAssociation'
      Association.new(owner, r)

    else
      puts "Unknown relation type: #{r['_type']}"
    end
  end

  class Target
    attr_reader :type, :name
    def initialize(type, name)
      @type, @name = type, name
    end
  end
    

  class Relation
    attr_reader :id, :name, :type, :json, :multliplicity,
                :source, :target, :owner, :node_id
    
    def initialize(owner, r)
      @owner = owner
      @source = owner
      @id = r['_id']
      @node_id = NodeId.id_to_i(@id)
      @name = r['name']
      @type = r['_type']
      @json = r
      @multiplicity = r['multiplicity'] || '1'
      @optional = @multiplicity and @multiplicity =~ /0\.\./
      @target = Target.new('Unknown', @name)
    end

    def stereotype
      unless defined?(@stereotype)
        @stereotype = @json['stereotype'] && Type.resolve_type(@json['stereotype'])
      end
      @stereotype
    end

    def data_type
      nil
    end

    def is_optional?
      @optional
    end

    def is_attribute?
      false
    end

    def is_property?
      false
    end

    def reference_type
      'HasProperty'
    end

    def rule
      @optional ? 'Optional' : 'Mandatory'
    end
    
    def is_optional?
      @optional
    end
  end
  
  class Association < Relation
    class End
      attr_accessor :name, :multiplicity, :optional, :navigable, :json
      
      def initialize(e)
        @name = e['name']
        @multiplicity = e['multiplicity']
        @optional = @multiplicity and @multiplicity =~ /0\.\./
        @id = e['_id']
        @navigable = e['navigable'] || false
        @json = e
      end

      def type
        unless defined?(@type)
          @type = Type.resolve_type(@json['reference'])
        end
        @type
      end
      
      def is_navigable?
        @navigable
      end
      
      def is_optional?
        @optional
      end
    end
    
    def initialize(owner, r)
      super(owner, r)
      @source = End.new(r['end1'])
      @target = End.new(r['end2'])
      @name = @source.name || @name
      @multiplicity = @source.multiplicity
      @optional = @source.optional
    end

    def target_node_id
      if @folder
        NodesIds['FolderType']
      else
        @target.type.node_id
      end
    end

    def is_folder?
      stereotype.name == 'Organizes'
    end

    def reference_type
      if is_folder?
        'Organizes'
      elsif stereotype
        stereotype.name
      else
        'HasComponent'
      end
    end
  end

  class Attribute < Relation
    def initialize(owner, a)
      super(owner, a)
      @data_type = a['type']
      @name = a['name']
      @owner = owner
      @json = a
      @target = Target.new(@data_type, @name)
    end
    
    def is_attribute?
      stereotype and stereotype.name =~ /Attribute/
    end

    def is_property?
      true
    end

    def resolve_data_type
      return @data_type if Aliases.include?(@data_type)
      NodeIds[@data_type]
    end
    
  end

  class Dependency < Relation
    def initialize(owner, r)
      super(owner, r)
      @source = nil
      @target = nil
    end

    def source
      unless @source
        @source = Type.resolve_type(@json['source'])
      end
      @source
    end
    
    def target
      unless @target
        @target = Type.resolve_type(@json['target'])
      end
      @target
    end
      

    def data_type
      return nil
    end
  end

  class Generalization < Dependency
  end
  
  class Realization < Dependency
  end
end
