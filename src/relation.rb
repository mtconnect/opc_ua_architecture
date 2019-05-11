require 'extensions'

module Relation
  @@connections = {}
  
  def self.clear
    @@connections.clear
  end
  
  def self.add_connection(e)
    id = e['idref']
    @@connections[id] = e
  end

  def self.connections
    @@connections
  end
  
  def self.create_association(owner, r)
    case r['type']
    when 'uml:Generalization'
      Generalization.new(owner, r)

    when 'uml:Realization'
      Realization.new(owner, r)

    when 'uml:Dependency'
      puts "!!! Creating a dependency..."
      Dependency.new(owner, r)

    when 'uml:Property'
      if r['association']
        Association.new(owner, r)
      else
        Attribute.new(owner, r)
      end

    when 'uml:Association', 'uml:Link'
      Association.new(owner, r)

    when 'uml:Constraint'
      Constraint.new(owner, r)

    when 'uml:Slot'
      Slot.new(owner, r)

    when 'uml:AssociationClassLink'
      Folder.new(owner, r)
      
    else
      puts "!! Unknown relation type: #{r['id']} - #{r['type']} for #{owner.name}"
    end
  end

  class Constraint
    include Extensions
    
    attr_reader :owner, :name, :specification, :documentation
                
    def initialize(owner, r)
      @name = r['name']
      @specification = r['specification']

      @extended = ::Relation.connections[@id]
      unpack_extended_properties(@extended)
    end
  end

  class Relation
    include Extensions
    
    attr_reader :id, :name, :type, :xmi, :multiplicity,
                :source, :target, :owner, :documentation,
                :stereotype, :constraints

    class Connection
      attr_accessor :name, :type, :type_id, :multiplicity
      
      def initialize(name, type_id, type = nil)
        @multiplicity = nil
        @name = name
        @type = type
        @type_id = type_id
      end

      def resolve_type
        if @type.nil? and @type_id
          @type = Type.type_for_id(@type_id)
        end
        if @type.nil?
          puts "    Connection: Cannot resolve type: '#{@type_id}' for #{@name}"
        end
        !@type.nil?
      end
    end
    
    def initialize(owner, r)
      @owner = owner
      @source = owner
      @id = r['id']
      @name = r['name']
      @type = r['type']
      @xmi = r
      @constraints = nil
      
      @extended = ::Relation.connections[@id]
      @multiplicity, @optional = get_multiplicity(r)

      @source = Connection.new('Source', nil, owner)
      @source.multiplicity = @multiplicity
      @stereotype = @target = nil
    end

    def final_target
      @target
    end

    def is_optional?
      @optional
    end
    
    def is_attribute?
      @stereotype and @stereotype =~ /Attribute/
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

    def node_class
      raise "Unknown ndoe class #{self.class.name} for #{@owner.name} '#{@name}'"
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
      if @target.nil?
        puts "    !!!! cannot resolve type for #{@owner.name}::#{@name} no target"
      else
        unless @target.resolve_type or @target.type_id =~ /^EA/
          raise "    !!!! cannot resolve target for #{@owner.name}::#{@name} #{self.class.name}"
        end
      end

      unless @source.resolve_type
        raise "    !!!! cannot resolve source for #{@owner.name}::#{@name} #{self.class.name}"
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
    attr_reader :final_target, :association
    
    class End < Connection
      include Extensions
      
      attr_accessor :name, :optional, :navigable, :xmi
      
      def initialize(e, tid)
        super(e['name'], tid)

        @multiplicity, @optional = get_multiplicity(e)
        @navigable = false
        @xmi = e
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

      sid = r.at('type')['idref']
      @source = End.new(r, sid)
      
      aid = r['association']
      assoc = r.document.at("//packagedElement[@id='#{aid}']")
      tid = assoc.at('ownedEnd/type')['idref']

      @association = ::Relation.connections[aid]
      unpack_extended_properties(@association)

      @target = End.new(assoc, tid)

      if @props['direction'] and @props['direction'] =~ /^Destination/
        @source, @target = @target, @source
      end
      @final_target = @target
      
      @name = @target.name || @name || @source.name
      @multiplicity = @target.multiplicity
      @optional = @target.optional
      @constraints = nil

      assoc.xpath('./ownedRule[@type="uml:Constraint"]').each do |c|
        name = c['name']
        spec = c.at('./specification')
        (@constraints ||= {})[name] = spec['body'] if spec
      end
    end

    def final_target
      @final_target
    end

    def is_reference?
      true
    end

    def target_node_name
      @target.type.name
    end

    def is_folder?
      @stereotype and @stereotype == 'Organizes'
    end

    def node_class
      if is_folder?
        'Object'
      elsif @stereotype
        'Stereotype'
      else
        'Object'
      end
    end

    def reference_type
      if @stereotype
        @stereotype
      else
        'HasComponent'
      end
    end

    def link_target(reference, type)
      @target = Connection.new(reference, nil, type)
    end

    def resolve_types
      super
      if is_folder?
        @target = Connection.new('OrganizedBy', nil, Type.type_for_name('FolderType'))
      end
    end
  end

  class Folder < Relation
    def initialize(owner, a)
      super(owner, a)
      @owner = owner
      @klass = a['classSide']
      @association = a['associationSide']
      @owner.class_link = self
    end

    def resolve_types
    end
  end

  class Attribute < Relation
    attr_reader :default
    
    def initialize(owner, a)
      super(owner, a)
      @name = a['name']
      dv = a.at('defaultValue')
      @default =  dv['value'] if dv

      element = Type.elements[owner.id]
      if element
        attr = element.at("./attributes/attribute[@idref='#{@id}']")
        @stereotype = attr.stereotype['stereotype'] if attr.at('./stereotype')
        @documentation = attr.documentation['value'] if attr.at('./documentation')
      end

      type = a.at('type')['idref']
      @target = Connection.new('type', type)
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

    def node_class
      'Variable'
    end

    def target_node_name
      'PropertyType'
    end
  end

  class Dependency < Relation
    def initialize(owner, r, attr = 'supplier')
      super(owner, r)
      @dependency = ::Relation.connections[@id]
      unpack_extended_properties(@dependency)

      @name = (@stereotype && @stereotype) unless @name
      @target = Connection.new('Target', r[attr])
    end
  end

  class Generalization < Dependency
    def initialize(owner, r)
      super(owner, r, 'general')
      @name = 'Supertype' unless @name
    end

    def reference_type
      'HasSubtype'
    end

    def node_class
      'ObjectType'
    end    
    
    def target_node_name
      "ObjectType"
    end
  end
  
  class Realization < Dependency
    def initialize(owner, r)
      super(owner, r, 'supplier')
      @name = 'Realization' unless @name      
    end

    def is_mixin?
      @stereotype and @stereotype == 'Mixes In'
    end
  end

  class Slot < Relation
    attr_reader :value
    
    def initialize(owner, a)
      super(owner, a)
      @name = a['name']
      @target = Connection.new('type', a['type'])
      @value = a['value']
    end

    def value
      @value
    end

    def is_array?
      @value and @value[0] == '['
    end

    def is_property?
      true
    end

    def node_class
      'Variable'
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
