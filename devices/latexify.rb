require 'redcarpet'

class Table
  attr_reader :tables
  
  def initialize
    @tabulars = []
    @current = @caption = @label = nil
  end

  def complete
    @current = nil
  end

  def current
    if @current
      @current
    else
      @tabulars << Tabular.new
      @current = @tabulars.last
    end
  end

  def  caption(caption, label)
    @caption, @label = caption, "table:#{label}"
  end

  def generate    
      caption = "\n  \\caption{#{@caption}}" if @caption
      label = "\n  \\label{#{@label}}" if @label

      content = @tabulars.map(&:generate).join('')
      
      text = <<EOT

\\begin{table}[ht]
  \\centering#{caption}#{label}
  \\fontsize{9pt}{11pt}\\selectfont
#{content}
\\end{table}
EOT
      text
  end
  
  class Tabular
    attr_accessor :rows, :columns

    
    class Cell
      attr_reader :text, :merge, :count
      def initialize(text)
        case text
        when /^>\[(\d+)\]\s+(.+)$/
          @merge = :right
          @text = $2
          @count = $1.to_i
        when 'v', 'V'
          @merge = :down
          @text = ''
        else
          @text = text
          @merge = nil
        end                 
      end

      def generate
        if @merge == :right
          "\\multicolumn{#{@count}}{|l|}{#{@text}}"
        else
          @text
        end
      end
    end

    class Column
      attr_accessor :alignment
      
      def initialize(name)
        w = nil
        @name = name.sub(/\[([^\]]+)\]/) { |s| w = $1; '' }
        @format =  w ? "{#{w}}" : nil
        @alignment = nil
      end

      def format
        s =  case @alignment
             when :right
               'r'

             when :center
               'c'

             else
               @format ? 'p' : 'l'
             end


        "#{s}#{@format}"
      end

      def name
        "\\textbf{#{@name}}"
      end
    end

    class Row
      attr_reader :cells
      
      def initialize
        @cells = []
      end

      def add_cell(text)
        @cells << Cell.new(text)
      end

      def generate
        skip = 0
        cs = @cells.map do |c|
          if c.text.empty? and skip > 0
            skip -= 1
            nil
          else          
            skip = c.count - 1 if c.merge == :right
            c.generate
          end
        end.compact.join(' & ')
      end
    end
    
    def initialize
      @rows = []
      @columns = []
      @index = 0
      @header = true
      @row = nil
      @completed = false
    end

    def add_cell(name, align)
      if @header
        @columns << Column.new(name)
      else
        @row = Row.new unless @row
        @row.add_cell(name)
        
        @columns[@index].alignment = align if align
        @index += 1
      end
    end

    def add_row(row)
      @rows << @row if @row
      @header = false
      @row = nil
      @index = 0
    end

    def completed?
      @completed
    end

    def complete
      @completed = true
    end

    def generate
      s = " \\\\ \\hline\n"
      columns = '| ' + @columns.map(&:format).join(' | ') + ' |'
      headers = @columns.map(&:name).join(' & ') + s
      content = @rows.map(&:generate).join(s) + s
      
      text = <<EOT

  \\begin{tabular}{#{columns}}
  \\hline
#{headers}
#{content}
  \\end{tabular}
EOT
      text
    end
  end
end

module Redcarpet
  module Render
    class Latex < Base
      def initialize(options = {})
        super()
        @close = []
        @table = nil
        @lazy = nil
      end

      def check_caption(text)
        if text =~ /^[ \t]*\[([^\]]+)\][ \t]*(\[([^\]]+)\])?/
          caption = $1
          if $3
            label = $3
          else
            label = caption.gsub(' ', '')
          end
          [caption, label]
        else
          nil
        end 
      end

      def expand_macros(text)
        text.gsub(/\{\{([a-zA-Z0-9_]+)(\(([^\)]+)\))?\}\}/) do |s|
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

          else
            "\\#{$1}{#{$3}}"
          end
        end
      end

      def normal_text(text)
        if text =~ / ->/
          text.gsub(/ ->/, " $\\rightarrow$")
        else
          text
        end
      end

      def block_code(code, language)
        line = 1
        if language =~ /^([A-Za-z]+)@(\d+)/
          language = $1
          line = $2
        end

        lang = "\\lstset{language=#{language.upcase},numbers=left,xleftmargin=2em}" if language

        @lazy = lambda do |caption, label|
          options = []
          options << "firstnumber=#{line}" if line
          options << "caption={#{caption}}" if caption
          options << "label={lst:#{label}}" if label
          
        <<EOT
#{lang}
\\begin{lstlisting}[#{options.join(',')}]
#{code}
\\end{lstlisting}
EOT
        end
        ''
      end

      def codespan(code)
        "\\texttt{#{code}}"
      end

      def header(content, level)
        title = expand_macros(content)
        label = nil
        title.sub!(/\{#([^}]+)\}/) { |t| label = $1; '' }
        head = case level
        when 1
          "\n\\section{#{title}}\n"

        when 2
          "\n\\subsection{#{title}}\n"

        when 3
          "\n\\subsubsection{#{title}}\n"
          
        when 4
          "\n\\paragraph{#{title}}\n"
          
        when 5
          "\n\\subparagraph{#{title}}\n"
        end

        if label
          "#{head}\\label{#{label}}\n"
        else
          head
        end
      end

      def superscript(text)
        text = "\\copyright" if text == '-c-'
        "\\textsuperscript{#{text}}"
      end

      def raw_html(html)
        case html
        when /align="center"/
          @close.push "\\end{center}"
          "\\begin{center}"

        when /style="font-size: 150%"/
          @close.push '}'
          "\\Large{"
          
        when /^<\//
          @close.pop
        else
          html
        end
      end

      def double_emphasis(content)
        text = expand_macros(content)
        "\\textbf{#{text}}"
      end

      def emphasis(content)
        text = expand_macros(content)
        "\\textit{#{text}}"
      end

      def highlight(text)
        "\\emph{#{text}}"
      end

      def underline(content)
        "\\underline{#{content}}"
      end

      def image(link, title, alt)
        puts "Image: #{link}, #{title}, #{alt}"
        if link =~ /\.tex$/
          "\\input{#{link}}"
        else
          if alt
            caption = alt
            lt = title
          else
            caption = title
            lt = title.gsub(' ', '')
          end

          label = "  \\label{fig:#{lt}}" if alt
          
          <<EOT
\\begin{figure}[ht]
  \\centering
  \\includegraphics[width=\\textwidth]{#{link}}
  \\caption{#{caption}}
#{label}
\\end{figure}
EOT
        end
      end

      def link(link, title, content)
        puts "Link: #{link}, #{title}"
        text = "\\input #{link}"
      end

      def linebreak
        " \\newline "
      end

      def hrule
         "\\hline"
      end

      def entity(text)
        text
      end

      def paragraph(content)
        text = expand_macros(content)
        
        if @table or @lazy
          caption, label = check_caption(text)
          if @table
            @table.caption(caption, label)
            rendered = "#{@table.generate}\n"
            @table = nil
          else
            rendered = @lazy.call(caption, label)
            @lazy = nil
          end
          rendered += "#{text}\n" unless caption
          rendered
        else
          "\n#{text}\n"
        end
      end

      def list(content, list_type)
        type = case list_type
               when :ordered
                 'enumerate'
               when :unordered
                 'itemize'
               end
        "\n\\begin{#{type}}\n#{content}\\end{#{type}}\n"
      end

      def list_item(content, list_type)
        text = expand_macros(content)
        "  \\item #{text}"
      end

      def table(header, content)
        @table.complete
        ''
      end

      def table_row(content)
        @table.current.add_row(content) if @table
        ''
      end

      def table_cell(content, alignment)
        text = expand_macros(content)
        @table ||= Table.new
        @table.current.add_cell(text, alignment)
        ''
      end
    end
  end
end

markdown = Redcarpet::Markdown.new(Redcarpet::Render::Latex, {superscript: true,
                                                              autolink: true,
                                                              fenced_code_blocks: true,
                                                              space_after_headers: true,
                                                              tables: true,
                                                              strikethrough: true,
                                                              no_intra_emphasis: true,
                                                              footnotes: true,
                                                              lax_spacing: true,
                                                              underline: true,
                                                              no_images: false
                                                             })

Dir.mkdir('converted') unless File.exists?('converted')

if ARGV.length > 0
  files = ARGV
else
  files = Dir['*.md']
end

files.each do |f|
  dest = "converted/#{f}.tex"
  puts "Rendering #{f} -> #{dest}"
  File.write(dest, markdown.render(File.read(f)))
end
