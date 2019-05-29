
require 'nokogiri'
require 'uri'

doc = nil
File.open(ARGV[0]) do |f|
  doc = Nokogiri::XML(f).slop!
  doc.remove_namespaces!
end

xmi = nil
File.open(ARGV[1]) do |f|
  xmi = Nokogiri::XML(f).slop!
end

ns = { 'xmi' => xmi.namespaces['xmlns:xmi'] }
p ns

doc.xpath('//documentation').each do |d|
  
  puts "------------------------"
  
  grand = d.parent.parent

  docs = URI.decode(d['value']).gsub('&#10;', '&#xA;')

  path = attr = nil
  begin
    case grand.name
    when 'packagedElement'
      type = name = URI.decode(grand['name'])
      uml = grand['type']
      uml = 'uml:Class' if uml == 'uml:Stereotype'
      path ='./properties'
      attr = 'documentation'

    when 'ownedAttribute', 'ownedRule', 'ownedOperation'
      type = URI.decode(grand.parent['name'])
      name = URI.decode(grand['name'])
      uml = grand.parent['type']
      path ="./attributes/attribute[@name='#{name}']/documentation"
      attr = 'value'
      
    when 'generalization'
      type = URI.decode(grand.parent['name'])
      name = "Generalization"
      uml = grand.parent['type']

    when 'ownedMember'
      type = URI.decode(grand.parent['name'])
      name, = grand.ownedEnd.map { |e| e['name'] }.compact
      uml = grand.parent['type']
      
      
    when 'node'
      next

    else
      raise "Unknown type: #{grand.name} #{d.line}"
    end

    puts "Parent element: #{uml} #{grand.name} #{type}::#{name}"
    
    puts "------------------------"
    puts URI.decode(d['value'])
    puts "------------------------\n\n"

    if path and attr
      element = xmi.at("//element[@xmi:type='#{uml}' and @name='#{type}']", ns)
      if element
        node = element.at(path)
        puts "updating docs for #{node.name}"
        node[attr] = docs
      end

    end
  rescue
    puts $!, $!.backtrace
    puts d.line
  end
end

File.open('MTConnect Extract Docs.xmi', 'w') do |f|
  xmi.write_xml_to(f)
end
