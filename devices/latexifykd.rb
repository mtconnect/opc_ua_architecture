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
        el.value.sub(/\{\{([a-zA-Z0-9_]+)(\(([^\)]+)\))?\}\}/) do |s|
          command, args = $1, $3.gsub(/\\([<>])/, '\1')
          case command
          when 'term'
            "\\gls{#{args}}"
            
          when 'termplural'
            "\\glspl{#{args}}"

          when 'latex'
            args

          when 'table'
            "\\ref{table:#{args}}"

          when 'figure'
            "\\ref{fig:#{args}}"

          when "span"
            @span = args.to_i
            ''

          when 'markdown'
            kd = ::Kramdown::Document.new(args.gsub(/<br\/?>/, "\n"), input: 'MTCKramdown')
            kd.to_mtc_latex
            
          else
            "\\#{command}{#{args}}"
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
          caption = latex_caption(caption)
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
        sep = opts[:sep] || "\\hline"
        el.children.map {|c| send("convert_#{c.type}", c, opts) }.compact.join(' & ') << " \\\\ #{sep}\n"
      end

      def convert_thead(el, opts)
        opts = opts.dup.merge(style: 'textbf', sep: "\\specialrule{1.5pt}{0pt}{0pt}")
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

      def convert_ul(el, opts)
        if el.attr['class'] == 'tight'
          type = el.type == :ul ? 'itemize' : 'enumerate'
          <<EOT
\\begin{#{type}}
\\setlength\\itemsep{-0.5em}
#{inner(el, opts)}\\end{#{type}}
EOT
        else
          super
        end
      end
      alias convert_ol convert_ul

      def convert_text(el, opts)
        kls =  opts[:parent].attr['class']
        close = open = nil
        case kls
        when 'large'
          open = '\\Large{'
          close = '}'
        end
          
        "#{open}#{super}#{close}"
      end

      def convert_p(el, opts)
        text = ''
        close = nil
        case el.attr['class']
        when 'center'
          text << "\\begin{center}\n"
          close = "\\end{center}\n"
        end
        
        if el.children.size == 1 && el.children.first.type == :img
          text << convert_img(el.children.first, opts)
        else
          text << "#{latex_link_target(el)}#{inner(el, opts)}\n\n"
        end
        text << close if close
        
        text
      end

      def convert_img(el, opts)
        src = el.attr['src']
        alt = el.attr['alt']
        title = el.attr['title']

        puts "Image: #{src}, #{alt}, #{title}"
        if src =~ /\.tex$/
          "\\input{#{src}}\n"
        else
          caption = alt
          label = "  \\label{fig:#{title}}" if title
          
          <<EOT
\\begin{figure}[ht]
  \\centering
  \\includegraphics[width=\\textwidth]{#{src}}
  \\caption{#{caption}}
#{label}
\\end{figure}
EOT
        end
      end

      def latex_caption(text)
        text.gsub(/`([^`]+)`/, '\\texttt{\1}')
      end

      def convert_labels(text)
        text.gsub(/\{#([^}]+)}/, '\\label{\1}')
      end

      def convert_math(el, _opts)
        convert_labels(super)
      end


      def convert_codeblock(el, _opts)
        language = extract_code_language(el.attr)
        line = (el.attr['start'] || 1).to_i
        escape = el.attr['escape']
        caption, label = caption_and_label(el, 'lst')
        
        code = el.value
        code = convert_labels(code) if escape

        options = ['numbers=left', 'xleftmargin=2em', "firstnumber=#{line}"]
        options << "language=#{language.upcase}" if language
        options << "caption={#{caption}}" if caption
        options << "label={lst:#{label}}" if label
        options << "escapechar={#{escape}}" if escape
        
        <<EOT
\\begin{lstlisting}[#{options.join(',')}]
#{code}\\end{lstlisting}
EOT
      end
    end
  end
end

Dir.mkdir('converted') unless File.exists?('converted')

if ARGV.length > 0
  files = ARGV
else
  files = Dir['*.md'].sort
end

files.each do |f|
  dest = "converted/#{f}.tex"
  puts "\nRendering #{f} -> #{dest}"
  kd = Kramdown::Document.new(File.read(f), input: 'MTCKramdown')
  File.write(dest, kd.to_mtc_latex)
  puts kd.warnings
end
