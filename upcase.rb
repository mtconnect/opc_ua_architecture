require 'json'

uml = File.open('MTConnect OPC-UA Devices.mdj').read
doc = JSON.parse(uml)

devices = doc['ownedElements'].select { |e| e['name'] == 'MTConnectDevices' }

def find_attrs(e, depth = 0)
  puts "#{'  ' * depth}#{e['name']}:#{e['_type']}"
  if e.include?('ownedElements')
    e['ownedElements'].each do |f|      
      find_attrs(f, depth + 1)
    end
  end
  if e.include?('attributes')
    e['attributes'].each do |a|
      a['name'][0] = a['name'][0].upcase
      puts "#{'  ' * depth}      - #{a['name']}"
    end
  end
end

devices.each do |e|
  find_attrs(e)
end

File.open('MTConnect OPC-UA Devices 2.mdj', 'w') do |f|
  f.puts JSON.pretty_generate(doc)
end
