require 'nodeset_type'
require 'model'

class Model
  def self.generate_nodeset(model)
    @@models[model].generate_nodeset
  end

  def generate_nodeset
    @types.each do |type|
      if type.parent.nil? or type.parent.model != self
        recurse_types(type)
      end
    end
  end

  def recurse_types(type)
    if type.type == 'UMLClass' or type.type == 'UMLStereotype' or
        type.type == 'UMLEnumeration' or type.type == 'UMLDataType' or
        type.type == 'UMLObject'
      type.generate_nodeset
    end

    type.children.each do |t|
      recurse_types(t) if t.model == self
    end
  end  
end
