require 'csv'
require 'set'

class IdManager
  def load_reference_documents(clean)
    # Parse Reference Documents.
    if empty? or clean
      ['OPC_UA_Nodesets/Opc.Ua.NodeSet2.xml'].each do |f|
        puts "Parsing OPC UA Nodeset: #{f}"
        File.open(f) do |x|
          doc = REXML::Document.new(x)
          
          # Copy aliases
          doc.root.each_element('//Aliases/Alias') do |e|
            add_alias(e.attribute('Alias').value)
          end
          
          doc.root.elements.each do |e|
            parent, name, id, sym = e.attribute('ParentNodeId'), e.attribute('BrowseName'), e.attribute('NodeId'),
            e.attribute('SymbolicName')
            
            if name and id and (e.name =~ /Type$/o or
                                (sym and (sym.value =~ /ModellingRule/o or
                                          sym.value =~ /BinarySchema/o or
                                          sym.value =~ /XmlSchema/o)))
              self[name.value] = id.value 
            end
          end
        end
      end
      
      save
    end
  end
    
  
  def initialize(file, clean = false, start = 2000)
    @file = file
    @ids = Hash.new
    @aliases = Set.new
    @next_id = start
    @klasses = Array.new
    @referenced = Set.new
    pat = /#{Namespace}:/o

    CSV.foreach(@file) do |key, id, als|
      if !clean or key =~ pat
        @ids[key] = id
        if id =~ /ns=1;i=([0-9]+)$/o
          v = $1.to_i
          @next_id = v + 1 if v >= @next_id
        end
        @aliases << key if eval(als)
      end
    end
    puts "Next is #{@next_id}"
    
  rescue
    p $!
    puts "File #{@file} cannot be found, starting ids from #{start}"
  end

  def add_alias(key)
    @aliases << key
  end

  def add_node_class(node_id, name, klass, path = nil)
    pth = (Array(path).dup << name).join('_').gsub(/#{Namespace}:/, '')
    @klasses << [pth, node_id.sub(/.+?i=(\d+)/, '\1'), klass]
  end

  def each_alias(&block)
    @aliases.each(&block)
  end

  def add(key, id)
    @referenced << key
    @ids[key] = id
  end

  def alias_or_id(key)
    @referenced << key
    if @aliases.member?(key)
      key
    else
      @ids[key]
    end
  end

  def [](key)
    alias_or_id(key)
  end

  def raw_id(key)
    @referenced << key
    @ids[key]
  end

  def empty?
    @ids.empty?
  end

  def []=(key, id)
    # puts "Key #{key} with #{id} already defined" if @ids.include?(key)
    @referenced << key
    @ids[key] = id unless @ids.include?(key)
  end

  def id_for(key)
    @referenced << key    
    return @ids[key] if @ids.include?(key)
    
    id = "ns=#{Namespace};i=#{@next_id}"
    @ids[key] = id
    @next_id += 1
    id
  end

  def has_id?(key)
    @ids.include?(key)
  end

  def has_alias?(key)
    @aliases.member?(key)
  end

  def save
    pat = /#{Namespace}:/o
    CSV.open(@file, 'wb') do |csv|
      @ids.keys.sort.each do |key|
        if key !~ pat or @referenced.include?(key)
          csv << [key, @ids[key], @aliases.include?(key)]
        end
      end
    end

    CSV.open('MTConnect.NodeIds.csv', 'wb') do |csv|
      @klasses.sort.each do |row|
        csv << row
      end
    end
  end
end

    
