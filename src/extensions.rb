module Extensions
  def unpack_extended_properties(ele)
    if ele
      @props = ele.at('./properties')
      if @props
        @documentation = REXML::Text::unnormalize(@props['documentation']) if @props['documentation']
        @stereotype = @props['stereotype']
        @alias = @props['alias']
      end
      d = ele.at('./documentation')
      @documentation = d['value'] if d
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
