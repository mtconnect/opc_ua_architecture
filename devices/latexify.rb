require 'redcarpet'



module Redcarpet
  module Render
    class Latex < Base

      class TableCell
        attr_accessor :text, :format
        
        def initialize(text, format)
          @text, @format = text, format
        end
      end

      def initialize(options = {})
        super()
        @close = []
        @table = nil
        reset_table
      end

      def reset_table
        @header = []
        @caption = ''
        @collect_header = true
        @collect_alignment = true
        @cell_index = 0
      end

      def normal_text(text)
        text
      end

      def block_code(code, language)
        "\\texttt{#{code}}"
      end

      def codespan(code)
        block_code(code, nil)
      end

      def header(title, level)
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

      def double_emphasis(text)
        "\\textbf{#{text}}"
      end

      def emphasis(text)
        "\\textit{text}"
      end

      def linebreak
        "\\newline"
      end

      def paragraph(text)
        if @table
          if text =~ /^[ \t]*\[([^\]]+)\][ \t]*(\[([^\]]+)\])?/
            caption = $1
            if $2
              label = $2
            else
              label = caption.gsub(' ', '')
            end
          else
            caption = label = ''
          end
          text = @table.call(caption, label)
          @table = nil
          text
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
        "  \\item #{content}\n"
      end

      def table(header, content)
        headers = @header.map { |h| h.text }.join(' & ')
        columns = '| ' + @header.map { |c| c.format }.join(' | ') + ' |'

        @caption ||= ''

        reset_table
        
        @table = lambda do |caption, label|
          <<EOT

\\begin{table}
  \\centering
  \\caption{#{caption}}
  \\label{table:#{label}}
  \\fontsize{9pt}{11pt}\\selectfont
  \\begin{tabular}{#{columns}}
  \\hline
    #{headers} \\\\ \\hline
#{content}
  \\end{tabular}
\\end{table}
EOT
        end
        ''
      end

      def table_row(content)
        @collect_header = false        
        "    #{content[0..-4]} \\\\ \\hline\n"        
      end

      def table_cell(content, alignment)
        if @collect_header
          w = nil
          s = content.sub(/\[([^\]]+)\]/) { |s| w = $1; '' }
          format = if w
            "p{#{w}}"
          else
            "l"
          end
        
          @header << TableCell.new(s, format)
          
          content
        else
          if @cell_index < @header.length
            case alignment
            when :right
              @header[@cell_index].format = 'r'
            when :center
              @header[@cell_index].format = 'c'
            end
            @cell_index += 1
          end
          "#{content} & "
        end
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
                                                              underline: true
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
