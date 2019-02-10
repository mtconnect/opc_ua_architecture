require 'relation'

module Relation
  class Relation
    def create_name(parent)
      @node_name = "#{parent}/#{browse_name}"
    end
    
    def resolve_node_ids(parent)
      create_name(parent)
      @node_id = Ids.id_for(@node_name)
    end

    def node_id(path)
      if path
        @node_id = Ids.id_for(expand_name(path))
      else
        @node_id
      end
    end

    def expand_name(path)
      np = (path.dup << browse_name)
      np.join('/')
    end

    def reference_type_alias
      ref = reference_type
      if Ids.has_id?(ref)
        Ids.alias_or_id(ref)
      elsif stereotype
        stereotype.node_id
      else
        raise "!!!! Cannot find reference type for #{@owner.name}::#{@name}"
      end
    end
    
    def value_rank
      if is_array?
        1
      else
        -1
      end
    end
  end

  class Association
    def target_node_id
      if is_folder?
        Ids['FolderType']
      else
        @target.type.node_id
      end
    end
    
    def target_node_id
      if is_folder?
        Ids['FolderType']
      else
        @target.type.node_id
      end
    end    
  end

  class Attribute
    def target_node_id
      Ids['PropertyType']
    end
  end

  class Generalization
    def target_node_id
      Ids['ObjectType']
    end    
  end

  class Slot
    def target_node_id
      Ids['PropertyType']
    end
  end
end

