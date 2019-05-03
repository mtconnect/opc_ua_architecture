module Extensions
  def unpack_extended_properties(ele)
    if ele
      @props, = ele.xpath('./properties')
      if @props
        @documentation = REXML::Text::unnormalize(@props['documentation']) if @props['documentation']
        @stereotype = @props['stereotype']
      end
    end
  end

  def get_multiplicity(r)
    upper = lower = '1'
    upper = r.at('upperValue')['value'] if r.at('upperValue')
    lower = r.at('lowerValue')['value'] if r.at('lowerValue')

    [lower == upper ? upper : "#{lower}..#{upper}",
     optional = lower == '0']
  end
end
