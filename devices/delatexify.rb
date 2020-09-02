file = ARGV[0]
text = File.read(file)
out = text.gsub(/\\([a-zA-Z]+)(\{([^}]+)\})?/) do |m|
  commamd, text = $1, $3
  case $1
  when 'gls'
    "{{term(#{text})}}"

  when 'glspl'
    "{{termplural(#{text})}}"

  when 'cite'
    "{{cite(#{text})}}"

  when 'uaterm'
    "{{uablock(#{text})}}"

  when 'mtterm'
    "{{mtblock(#{text})}}"
    
  when 'uamodel'
    "{{uamodel(#{text})}}"
    
  when 'mtmodel'
    "{{mtmodel(#{text})}}"
    
  when 'uatype'
    "{{uatype(#{text})}}"
    
  when 'mtuatype'
    "{{mtuatype(#{text})}}"
    
  when 'section'
    "# #{text}"
    
  when 'subsection'
    "## #{text}"
    
  when 'subsubsection'
    "### #{text}"
    
  when 'paragraph'
    "#### #{text}"

  when 'texttt'
    "`#{text}`"

  when 'textit'
    "*#{text}*"

  when 'input'
    "{{latex(\input"

  when 'ref'
    case text
    when /^table:(.+)$/
      "{{table(#{$1})}}"
      
    when /^fig:(.+)$/
      "{{figure(#{$1})}}"
      
    else
      "{{ref(#{text})}}"
    end

  when 'label'
    " {\##{text}}"

  when 'item'
    '* '

  else
    "{{latex(#{m})}}"
  end
end

puts out

