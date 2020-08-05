require 'redcarpet'



module Redcarpet
  module Render
    class Latex < Base

      def initialize(options = {})
        super()
        @close = []
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
        case text
        when /^: (.+)$/
          @caption = $1
          ''
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
        fields = header.gsub(/\\\\ \\hline$/,'').split('&')
        headers = "    " + fields.map { |s| "\\textbf{#{s.strip}}" }.join(" & ") + " \\\\ \\hline"
        columns = ('|l' * fields.size) + '|'
        
        text = <<EOT

\\begin{table}
  \\centering
  \\caption{#{@caption}}
  \\label{table:#{@caption.gsub(' ', '')}}
  \\fontsize{9pt}{11pt}\\selectfont
  \\begin{tablular}{6in}{#{columns}}
  \\hline
#{headers}
#{content}
  \\end{tablular}
\\end{table}
EOT
        text
      end

      def table_row(content)
        "    #{content[0..-4]} \\\\ \\hline\n"
      end

      def table_cell(content, alignment)
        "#{content} & "
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

Dir['*.md'].each do |f|
  puts "Rendering #{f}"
  File.write("converted/#{f}.tex", markdown.render(File.read(f)))
end

