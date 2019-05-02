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
    upper = r.upperValue['value'] unless (r > 'upperValue').empty?
    lower = r.lowerValue['value'] unless (r > 'lowerValue').empty?
    [lower, upper]
  end
end
