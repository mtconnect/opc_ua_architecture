require 'nodeset_type'
require 'model'

class Model
  def self.generate_nodeset(root, model)
    @@models[model].generate_nodeset(root)
  end

  def generate_nodeset(root)
    @types.each do |type|
      if type.parent.nil? or type.parent.model != self
        recurse_types(root, type)
      end
    end
  end

  def recurse_types(root, type)
    if type.type == 'UMLClass' or type.type == 'UMLStereotype'
      puts type
      type.generate_nodeset(root) 
    end

    type.children.each do |t|
      recurse_types(root, t) if t.model == self
    end
  end  
end
