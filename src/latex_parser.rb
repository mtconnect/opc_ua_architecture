require 'rubygems'
require 'treetop'
require 'set'
require 'memoist'

Treetop.load 'src/latex'

class LatexParser
  attr_reader :entries
  
  def parse_glossary(file)
    res = parse(File.read(file))
    unless res
      $logger.fatal failure_reason
      $logger.fatal terminal_failures.join("\n")
      exit
    end

    @indexes = Hash.new { |h, k| h[k] = [] }        
    @entries = Hash.new
    @plural = Hash.new
    @singular = Hash.new
    
    res.elements.each do |e|
      next unless Latex::GlossaryEntry === e and e.has_key?(:category) and
        e.category == 'model'

      if e.kind
        e.kind.each do |k|
          @indexes[k] << e
        end
      end

      name = e.name
      @entries[name] = e
      unless e.name_property.start_with?(/[a-z]/)
        $logger.debug "Adding #{e.name_property}"
        @entries[e.name_property] = e
      end
      if e.has_key?(:elementname)
        $logger.debug  "Adding #{e.elementname}"
        @entries[e.elementname] = e
      end        
      @entries[e.plural] = e if e.has_key?(:plural)

      $logger.debug "Adding #{name}"

      if e.name_list.length == 1 and e.has_key?(:plural)
        plural = e.plural.downcase
        @entries[plural] = e
        
        @singular[plural] = name
        @plural[name] = plural
      end
    end

    $logger.info "Entries: #{@entries.length}"
    @indexes.each do |kind, list|
      $logger.info "  #{kind}: #{list.count}"
    end
  end

  def plural(word)
    return @plural[word] if @plural.include?(word)
    case word
    when /(o|s|ss|ch|x)$/
      "#{word}es"

    when /y$/
      "#{words.slice(0...-1)}ies"

    else
      "#{word}s"
    end
  end

  def singular(word)
    return @singular[word] if @singular.include?(word)
    case word
    when /(o|s|ss|ch|x)es$/
      word.slice(0...-2)

    when /ies$/
      "#{word.slice(0...-3)}y"
      
    when /s$/
      word.slice(0...-1)

    else
      word
    end
  end

  def entries(m)
    [m, m.to_s.downcase.to_sym].each do |s|
      return @indexes[s] if @indexes.include?(s)
      ms = singular(s.to_s).to_sym
      return @indexes[ms] if @indexes.include?(ms)
      ms = plural(s.to_s).to_sym
      return @indexes[ms] if @indexes.include?(ms)
    end    
  end
  
  def method_missing(m, *args, &block)
    r = entries(m)
    return r if r

    $logger.error "Cannot resovle '#{m}', tried '#{plural(m.to_s)}' and '#{singular(m.to_s)}'"
    super
  end

  def [](key)
    @entries[key]
  end
end

module Latex
  class GlossaryEntry
    extend Memoist
    
    attr_accessor :parent, :elements
    
    def initialize(text, range, elements)
      @elements = elements
    end

    def inspect
      "\#<#{self.class.name}: #{name.inspect} #{keys.inspect}>"
    end

    def name_list
      name_tokens.elements.map(&:value).compact
    end
    memoize :name_list

    def name
      name_list.join(' ')
    end
    memoize :name

    def facet
      if has_key?(:facet)
        return keys[:facet]
      elsif kind_of?(:sample)
        return 'float'
      else
        return 'string'
      end
    end

    def keys
      kys = Hash.new
      properties.elements.map(&:value).compact.each do |k, v|
        kys[k.to_sym] = v
      end
      if !kys.include?(:description) and respond_to? :long_description and
        long_description.respond_to? :value
        kys[:description] = long_description.value 
      end
      if kys.include?(:description) and kys.include?(:deprecated) and
            kys[:description] !~ /^DEPRECATED/
        kys[:description] = "DEPRECATED: #{kys[:description]}" 
      end
      kys
    end
    memoize :keys

    def <=>(other)
      self.name <=> other.name
    end

    def has_key?(key)
      keys.include?(key)
    end

    def name_property
      keys[:name].gsub('$', '')
    end

    def kind
      k = self.keys[:kind]
      k = k.split(',').map(&:to_sym) if k
      k
    end
    memoize :kind

    def [](key)
      keys[key]
    end

    def kind_of?(k)
      (kind and kind.include?(k))
    end
    
    def method_missing(method, *args, &block)
      if !keys.include?(method)
        $logger.error "Cannot find entry: #{@name} #{keys.inspect}"      
        super
      else
        keys[method]
      end
    end
    
    def dump
      $logger.info "Name: #{name.inspect}"
      $logger.info "Keys: #{keys.inspect}"
    end
    
    def to_s
      "#{name.inspect} -> #{keys.inspect}"
    end
  end
  
  class Property < Treetop::Runtime::SyntaxNode
    def value
      [key.text_value, context.value]
    end
  end
  
  class Command < Treetop::Runtime::SyntaxNode
    def command
      if !defined? @command
        @command = name.value
      end
      @command
    end

    def value
      if content.respond_to? :value
        content.value
      else
        command
      end
    end
  end
end
