require 'kramdown'


module Kramdown
  module Parser
    class MTCKramdown < Kramdown

      def initialize(source, options)
        super
        @span_parsers.unshift(:inline_macro)
      end

      INLINE_MACRO_START = /\{\{.*?\}\}/

      # Parse the inline math at the current location.
      def parse_inline_macro
        start_line_number = @src.current_line_number
        @src.pos += @src.matched_size
        @tree.children << Element.new(:macro, @src.matched, nil, category: :span, location: start_line_number)
      end
      define_parser(:inline_macro, INLINE_MACRO_START, '{{')
    end
  end

  
  module Converter
    class MtcLatex < Latex
      def initialize(root, options)
        @multi_table = false
        @skip = @span = nil
        super
      end
      
      def convert_macro(el, _opts)
        el.value.gsub(/\{\{([a-zA-Z0-9_]+)(\(([^\)]+)\))?\}\}/) do |s|
          case $1
          when 'term'
            "\\gls{#{$3}}"
            
          when 'termplural'
            "\\glspl{#{$3}}"

          when 'latex'
            $3

          when 'table'
            "\\ref{table:#{$3}}"

          when 'figure'
            "\\ref{fig:#{$3}}"

          when "span"
            @span = $3.to_i
            ''

          else
            "\\#{$1}{#{$3}}"
          end
        end
      end

      def caption_and_label(el, context)
        caption = el.attr['caption']
        if caption
          label = el.attr['label'] || caption.gsub(/[ ]+/, '')
          if context and not label.index(':')
            label = "#{context}:#{label}"
          end
        end
        [caption, label]
      end

      def convert_table(el, opts)
        cap, lbl = caption_and_label(el, 'table')
        
        # Check for multi-tables
        if cap
          caption = "\n  \\caption{#{cap}}"
          label = "\n  \\label{#{lbl}}"
        end

        align = el.options[:alignment].map {|a| TABLE_ALIGNMENT_CHAR[a] }

        if el.attr['format']
          default = el.attr['format'] 
          align.map! { |a| default }
        end

        el.attr.keys.each do |k|
          if k =~ /^format-(\d+)/
            align[$1.to_i - 1] = el.attr[k]
          end
        end

        columns = '| ' + align.map do |f|
          a, w = f.split
          a << "{#{w}}" if w
          a
        end.join(' | ') + ' |'

        continued = @multi_table
        if opts[:parent].children[opts[:index] + 1].type == :blank and
          opts[:parent].children[opts[:index] + 2].type == :table and
          opts[:parent].children[opts[:index] + 2].attr['caption'].nil?
          @multi_table = true
        else
          @multi_table = false          
        end

        text = ''
        if not continued
          text = <<EOT

\\begin{table}[ht]
  \\centering#{caption}#{label}
  \\fontsize{9pt}{11pt}\\selectfont
EOT
        end

        text<< <<EOT

  \\begin{tabular}{#{columns}}
  \\hline
#{inner(el, opts)}
  \\end{tabular}
EOT
        
      unless @multi_table
        text<< <<EOT
\\end{table}    
EOT
      end
        text
      end

      def convert_tr(el, opts)
        el.children.map {|c| send("convert_#{c.type}", c, opts) }.compact.join(' & ') << " \\\\ \\hline\n"
      end

      def convert_thead(el, opts)
        opts = opts.dup.merge(style: 'textbf')
        inner(el, opts)
      end

      def convert_tbody(el, opts)
        super
      end

      def convert_td(el, opts)
        text = inner(el, opts)
        if text.empty? and @skip and @skip > 0
          @skip -= 1
          nil
        else
          if @span
            text = "\\multicolumn{#{@span}}{|l|}{#{text}}"
            @skip, @span = @span - 1, nil
          end
          if opts[:style]
            "\\#{opts[:style]}{#{text}}"
          else
            text
          end
        end
      end
    end
  end
end

Dir.mkdir('converted') unless File.exists?('converted')

if ARGV.length > 0
  files = ARGV
else
  files = Dir['*.md']
end

files.each do |f|
  dest = "converted/#{f}.tex"
  puts "Rendering #{f} -> #{dest}"
  kd = Kramdown::Document.new(File.read(f), input: 'MTCKramdown')
  File.write(dest, kd.to_mtc_latex)
  puts kd.warnings
end
