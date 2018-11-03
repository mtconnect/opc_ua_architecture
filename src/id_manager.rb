require 'csv'
require 'set'

class IdManager
  def initialize(file, start = 2000)
    @file = file
    @ids = Hash.new
    @aliases = Set.new
    @next_id = start

    CSV.foreach(@file) do |key, id, als|
      @ids[key] = id
      if id =~ /ns=1;i=([0-9]+)$/o
        v = $1.to_i
        @next_id = v + 1 if v >= @next_id
      end
      @aliases << key if eval(als)
    end
    puts "Next is #{@next_id}"
    
  rescue
    puts "File #{@file} cannot be found, starting ids from #{start}"
  end

  def add_alias(key)
    @aliases << key
  end

  def each_alias(&block)
    @aliases.each(&block)
  end

  def add(key, id)
    @ids[key] = id
  end

  def alias_or_id(key)
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
    @ids[key]
  end

  def empty?
    @ids.empty?
  end

  def []=(key, id)
    # puts "Key #{key} with #{id} already defined" if @ids.include?(key)
    @ids[key] = id unless @ids.include?(key)
  end

  def id_for(key)
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
    CSV.open(@file, 'wb') do |csv|
      @ids.keys.sort.each do |key|
        csv << [key, @ids[key], @aliases.include?(key)]
      end
    end
  end
end

    