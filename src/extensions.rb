module Extensions
  def xmi_stereotype(e)
    id = e['xmi:id']
    type = e['xmi:type']
    attr = if type == 'uml:Class'
             'base_Class'
           else
             if e['association']
               id = e['association']
               'base_Association'
             else
               'base_Property'
             end
           end
    if attr
      stereo = e.document.root.at("/xmi:XMI/*[@#{attr}='#{id}']")
      stereo = e.document.root.at("/xmi:XMI/*[@base_Element='#{id}']") unless stereo
      stereo.name if stereo
    end
  end

  def xmi_documentation(e)
    comment = e.at('./ownedComment')
    comment['body'].gsub(/<[\/]?[a-z]+>/, '') if comment
  end

  def get_multiplicity(r)
    upper = lower = '1'
    upper = r.at('upperValue')['value'] if r.at('upperValue')
    lower = r.at('lowerValue')['value'] if r.at('lowerValue')

    [lower == upper ? upper : "#{lower}..#{upper}",
     optional = lower == '0']
  end
end
