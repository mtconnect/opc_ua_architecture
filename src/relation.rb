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

    when 'UMLAssociation', 'UMLLink'
      Association.new(owner, r)

    when 'UMLConstraint'
      Constraint.new(owner, r)

    when 'UMLSlot'
      Slot.new(owner, r)
      
    else
      puts "Unknown relation type: #{r['_type']}"
    end
  end

  class Constraint
    attr_reader :owner, :name, :specification, :documentation
                
    def initialize(owner, r)
      @name = r['name']
      @specification = r['specification']
      @documentation = r['documentation']
    end
  end

  class Relation
    attr_reader :id, :name, :type, :json, :multiplicity,
                :source, :target, :owner, :documentation,
                :stereotype, :tags

    class Connection
      attr_accessor :name, :type, :type_id, :multiplicity
      
      def initialize(name, type_id, type = nil)
        @multiplicity = nil
        @name = name
        @type = type
        if type_id.is_a? Hash
          @type_id = type_id['$ref']
        else
          @type_id = type_id
        end
      end

      def resolve_type
        if @type.nil? and @type_id
          @type = Type.type_for_id(@type_id)
        end
        if @type.nil?
          puts "    Cannot resolve type: '#{@type_id}' for #{@name}"
        end
        !@type.nil?
      end
    end
    
    def initialize(owner, r)
      @owner = owner
      @source = owner
      @id = r['_id']
      @name = r['name']
      @documentation = r['documentation']
      @type = r['_type']
      @tags = r['tags']
      @json = r
      @multiplicity = r['multiplicity'] || '1'
      @optional = (@multiplicity and @multiplicity =~ /^0\.\./) != nil

      @source = Connection.new('Parent', nil, owner)
      @stereotype = @target = nil
    end

    def final_target
      @target
    end

    def is_optional?
      @optional
    end
    
    def is_attribute?
      stereotype and stereotype.name =~ /Attribute/
    end

    def is_folder?
      false
    end

    def is_property?
      false
    end

    def is_mixin?
      false
    end

    def is_reference?
      false
    end

    def reference_type
      raise "Unknown reference #{self.class.name} for #{@owner.name} '#{@name}'"
    end
    
    def target_node_name
      raise "Unknown target node name for #{@owner.name} #{@name}"
    end

    def target_node_id
      raise "Unknown target node type for #{@owner.name} #{@name}"
    end

    def browse_name
      @name || "<#{@target.type.name.sub(/Type/, '')}>"
    end

    def resolve_types
      if @json['stereotype'] and !@json['stereotype'].empty?
        @stereotype = Type.resolve_type(@json['stereotype'])
        puts "Cannot resolve #{@json['stereotype'].inspect} for #{@owner.name}::#{@name}" unless @stereotype
      end
      if @target.nil?
        puts "    !!!! cannot resolve type for #{@owner.name}::#{@name} no target"
      else
        unless @target.resolve_type
          raise "    !!!! cannot resolve target for #{@owner.name}::#{@name} #{self.class.name}"
        end
      end

      unless @source.resolve_type
        raise "    !!!! cannot resolve source for #{@owner.name}::#{@name} #{self.class.name}"
      end

      if @stereotype and @stereotype.name =~ /Override/
        @name = @name.sub(/^./, '')
      end
    end

    def rule
      @optional ? 'Optional' : 'Mandatory'
    end

    def is_array?
      @multiplicity =~ /\.\.\*/
    end
    
    def is_optional?
      @optional
    end
  end
  
  class Association < Relation
    attr_reader :final_target
    
    class End < Connection
      attr_accessor :name, :optional, :navigable, :json
      
      def initialize(e)
        if e['reference']
          super(e['name'], e['reference'])
        else
          super(e['name'], nil)
          puts "!!!!!!! Missing type reference for #{@name} #{e.inspect}"
        end

        @multiplicity = e['multiplicity'] || '1'
        @optional = (@multiplicity and @multiplicity =~ /0\.\./) != nil

        @navigable = e['navigable'].nil? || e['navigable']
        @json = e
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
      @final_target = @target
        
      @name = @source.name || @name
      @multiplicity = @source.multiplicity
      @optional = @source.optional
    end

    def final_target
      @final_target
    end

    def is_reference?
      true
    end

    def target_node_name
      if is_folder?
        'FolderType'
      else
        @target.type.name
      end
    end

    def is_folder?
      stereotype and stereotype.name == 'Organizes'
    end

    def reference_type
      if stereotype
        stereotype.name
      else
        'HasComponent'
      end
    end

    def resolve_types
      super
      if is_folder?
        @target = Connection.new('OrganizedBy', nil, Type.type_for_name('FolderType'))
      end
    end
  end

  class Attribute < Relation
    attr_reader :default
    
    def initialize(owner, a)
      super(owner, a)
      @name = a['name']
      @owner = owner
      @default = a['defaultValue']
      @json = a
      @target = Connection.new('type', a['type'])
    end
    
    def is_property?
      true
    end

    def is_reference?
      !is_attribute?
    end    

    def reference_type
      'HasProperty'
    end

    def target_node_name
      'PropertyType'
    end
  end

  class Dependency < Relation
    def initialize(owner, r)
      super(owner, r)
      @name = (stereotype && stereotype.name) unless @name      

      @source = Connection.new('Source', r['source'])
      @target = Connection.new('Target', r['target'])
    end
  end

  class Generalization < Dependency
    def initialize(owner, r)
      super(owner, r)
      @name = 'Supertype' unless @name
    end

    def reference_type
      'HasSubtype'
    end
    
    def target_node_name
      "ObjectType"
    end
  end
  
  class Realization < Dependency
    def initialize(owner, r)
      super(owner, r)
      @name = 'Realization' unless @name      
    end

    def is_mixin?
      stereotype and stereotype.name == 'Mixes In'
    end
  end

  class Slot < Relation
    attr_reader :value
    
    def initialize(owner, a)
      super(owner, a)
      @name = a['name']
      @owner = owner
      @json = a
      @target = Connection.new('type', a['type'])
      @value = a['value']
    end

    def value
      @value
    end

    def is_property?
      true
    end

    def reference_type
      'HasProperty'
    end

    def target_node_name
      'PropertyType'
    end

    def resolve_types
      super
    rescue
      puts "Warn: Cannot resolve type #{@owner.name}::#{@name}"
    end
  end
end
