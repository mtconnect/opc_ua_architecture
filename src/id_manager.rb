require 'csv'
require 'set'
require 'nokogiri'

class IdManager
  attr_reader :version, :pub_date

  
  def load_reference_documents(clean)
    # Parse Reference Documents.
    if empty? or clean
      f = File.join(File.dirname(__FILE__), '..', 'OPC_UA_Nodesets', 'Opc.Ua.NodeSet2.xml')
      $logger.info "Parsing OPC UA Nodeset: #{f}"
      File.open(f) do |x|
        doc = Nokogiri::XML(x).slop!
        doc.remove_namespaces!

        # Get model info
        model = doc.UANodeSet.Models.Model
        @version = model['Version']
        @pub_date = model['PublicationDate']

        $logger.info "Version: #{@version}, PublicationDate: #{@pub_date}"
        
        # Copy aliases
        doc.xpath('//Aliases/Alias').each do |e|
          add_alias(e['Alias'])
        end
        
        doc.UANodeSet.element_children.each do |e|
          parent, name, id, sym = e['ParentNodeId'], e['BrowseName'], e['NodeId'],
                                  e['SymbolicName']
          
          if name and id and (e.name =~ /Type$/o or
                              (sym and (sym =~ /ModellingRule/o or
                                        sym =~ /BinarySchema/o or
                                        sym =~ /XmlSchema/o)))
            self[name] = id 
          end
        end
      end
      
      save
    end
  end
    
  
  def initialize(file, opc_file, clean = false, start = 2000)
    @file = file
    @opc_file = opc_file
    @ids = Hash.new
    @aliases = Set.new
    @next_id = start
    @klasses = Array.new
    @referenced = Set.new
    pat = /#{Namespace}:/o

    CSV.foreach(@file) do |key, id, als|
      if key == 'x:Version'
        @version = id
      elsif  key == 'x:PublicationDate'
        @pub_date = id
      elsif !clean or key =~ pat
        @ids[key] = id
        if id =~ /ns=1;i=([0-9]+)$/o
          v = $1.to_i
          @next_id = v + 1 if v >= @next_id
        end
        @aliases << key if eval(als)
      end
    end
    $logger.info "Next is #{@next_id}"
    
  rescue
    $logger.error $!.inspect
    $logger.error  "File #{@file} cannot be found, starting ids from #{start}"
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
      csv << ['x:Version', @version, nil]
      csv << ['x:PublicationDate', @pub_date, nil]
      
      @ids.keys.sort.each do |key|
        if key !~ pat or @referenced.include?(key)
          csv << [key, @ids[key], @aliases.include?(key)]
        end
      end
    end

    CSV.open(@opc_file, 'wb') do |csv|
      @klasses.sort.each do |row|
        csv << row
      end
    end
  end
end

    
