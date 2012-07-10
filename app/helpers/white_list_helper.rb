module WhiteListHelper

  def simple_tasty_format(text)
    '<p>' + text.to_s.
      gsub(/\r\n?/, "\n").                    # \r\n and \r -> \n
      gsub(/\n\n+/, '</p><p>').          # 2+ newline  -> paragraph
      gsub(/([^\n]\n)(?=[^\n])/, '\1<br />') + '</p>' # 1 newline   -> br
  end

  def simple_tasty_format_without_p(text)
    text.to_s.
      gsub(/\r\n?/, "\n").                    # \r\n and \r -> \n
      gsub(/\n\n+/, '<br /><br />').          # 2+ newline  -> paragraph
      gsub(/([^\n]\n)(?=[^\n])/, '\1<br/>') # 1 newline   -> br
  end
  
  def white_list_video_entry(text)
    white_list_html_with_rescue(text, :media_width => 420)
  end

  
  def white_list_entry(text, options = {})
    white_list_html_with_rescue(text, options.dup)
  end
  
  def white_list_sidebar(text, options = {})
    white_list_html_with_rescue(text, :link_target => '_blank')
  end
  
  def white_list_comment(text)
    white_list_html_with_rescue(text, :media_width => 290)
  end
  
  def white_list_html_with_rescue(html, options = {})
    begin
      white_list_html(html, options)
    rescue Exception => ex
      Airbrake.notify(
        :error_class    => 'WhiteListHtml Error',
        :error_message  => "WhiteListHtml: #{ex.message}",
        :backtrace      => ex.backtrace,
        :parameters     => options.merge(:html => html)
      )

      Rails.logger.error "> Failed to render the following content"
      Rails.logger.error html
      Rails.logger.error "> Exception was: #{ex.message}"
      
      "<p class='t-entry-exception'>внутреняя ошибка сервера</p>"
    end
  end  

  def white_list_html(html, options = {})
    valid_flash_params = %w(movie allowfullscreen allowscriptaccess wmode flashvars)
    valid_iframe_params = %w(title width height src frameborder allowfullscreen alt)
    
    return html if html.blank?
    
    html.gsub!('&amp;', '&')
    html.gsub!('amp;', '')
    
    media_width = options[:media_width] || 400
    link_target = options[:link_target] || '_blank'
    
    doc1 = Hpricot(simple_tasty_format(html), :fixup_tags => true)

    # Делаем сканирование элементов
    allowed_tags = Set.new(%w(a b i s br img p strong em ul ol li h1 h2 h3 h4 h5 h6 div object iframe param))
    allowed_attributes = Set.new(%w(class id href alt src width height title border tag name value style))
    
    doc = Hpricot(sanitize(doc1.to_html, :tags => allowed_tags, :attributes => allowed_attributes), :fixup_tags => true)

    # Удаляем пустые параграфы
    # (doc/"//p[text()='']").remove    
    
    (doc/"//p").each do |paragraph|
      next if paragraph.children.blank?

      paragraph.children.select { |e| e.text? }.each do |text|
        new_text = auto_link(text.inner_text)

        # [andy] -> ссылка на пользователя
        new_text.gsub!(/(\[([a-z0-9_-]{2,20})\])/i) do
          user = User.find_by_url($2)
          user ? "<a href='#{user_url(user)}' class='t-entry-tlog'>#{user.url}</a>" : $1
        end

        # @andy -> ссылка на пользователя
        new_text.gsub!(/(^|\s+|\n)(\@([a-z0-9_-]{2,20}))(\,|\:|\;|\.(\s+|$)|\s+|$)/i) do
          user = User.find_by_url($3)
          user ? "#{$1}<a href='#{user_url(user)}' class='t-entry-tlog'>@#{user.url}</a>#{$4}" : $1
        end

        text.swap(new_text) unless new_text.blank?        
      end
    end
    
    # # Создаем slideshow из последовательных //a/img или просто //img
    # ss = [[]]
    # ss_idx = 0
    # (doc/"//img").each do |img|
    #   node = img
    #   node = node.parent if node.parent && node.parent.name == 'a'
    #   
    #   # skip few br backwards
    #   ps = node.previous_sibling
    #   ps = ps.previous_sibling if ps && ps.name == 'br'
    #   ps = ps.previous_sibling if ps && ps.name == 'br'
    #   
    #   if ss[ss_idx].any? && ps && ss[ss_idx].last != ps
    #     puts "skip because diff sibling #{ps.to_html} with #{ss[ss_idx].last.to_html}"
    #     ss_idx += 1
    #     ss[ss_idx] = []
    #   end
    # 
    #   ss[ss_idx] << node
    #   
    #   # should include next one with this?
    #   pt = ''
    #   nn = node
    #   while nn = nn.next do
    #     break if nn.elem? && nn.name != 'br'
    #     pt += nn.to_plain_text.strip
    #   end
    #   
    #   if !pt.strip.empty?
    #     ss_idx += 1
    #     ss[ss_idx] = []
    #   end
    #   
    # end if (doc/"//img").length > 1
    # 
    # ss.each do |images|
    #   next if images.empty? || images.first.empty? || images.length <= 1
    #   
    #   replacement = images.map(&:to_s).join("\n")
    #   
    #   images[0].swap("<div class='t-slides'><div class='t-slides-container'>#{replacement}</div><a href='#' class='t-slide-prev'><img src='/images/slides/arrow-prev.png' width='24' height='43' alt='Arrow Prev'></a><a href='#' class='t-slide-next'><img src='/images/slides/arrow-next.png' width='24' height='43' alt='Arrow Next'></a></div>")
    #   # images[1..images.length].each do |image|
    #   #   # image.swap('')
    #   # end
    # end if ss.any?
    
    # rewrite images for me
    (doc/"//img").each do |img|
      img.attributes['src'] = resized_image_path(img.attributes['src'], media_width)
      
      # remove buggy links
      img.parent.swap(img.to_html) if img.parent && img.parent.name == 'a' && img.parent.attributes['href'] && img.parent.attributes['href'] =~ /(www\.radikal\.ru)/i
      
      # img.parent.swap(img.to_html) if img.parent && img.parent.name == 'p' && img.parent.children.length == 1
    end

    
    (doc/"//iframe").each do |iframe|
      valid_iframe_attrs = %w(width height src title border frameborder)

      attrs = {}
      valid_iframe_attrs.each { |k| attrs[k] = iframe.attributes[k] unless iframe.attributes[k].blank? }

      # check wether this is allowed
      if attrs['src'] && allowed_flash_domain?(attrs['src'])
        # scale height?
        scale_height = true
        scale_height = false if attrs['src'].include?('prostopleer.com')
        
        width = (attrs['width'] && attrs['width'].ends_with?('%')) ? (media_width * attrs['width'].to_i / 100) : (attrs['width'].to_i || media_width)
        # width  = attrs['width'].to_i || media_width
        height = attrs['height'].to_i || media_width

        if width > media_width
          attrs['height'] = scale_height ? ((media_width / width.to_f) * height.to_f).to_i : height
          attrs['width']  = media_width
        end
        
        iframe.swap content_tag(:iframe, nil, attrs)
      else
        iframe.swap("<div class='t-entry-warn'>Извините, но вставлять такой код запрещено.</div>")
      end
    end
    
    
    (doc/"//object").each do |flash|
      width = nil
      
      # try attr width - px
      width ||= $1.to_i if flash.attributes['width'].match(/^(\d+)$/)

      # try attr width - %
      width ||= media_width * flash.attributes['width'].to_i / 100 if flash.attributes['width'].match(/^\d+%$/)

      # try style width - px
      width ||= $2.to_i if flash.attributes['style'].match(/width:(\s+)?(\d+)px/i)

      # try style width - %
      width ||= (media_width * $2.to_i / 100) if flash.attributes['style'].match(/width:(\s+)?(\d+)%/i)

      # finalize with default
      width ||= media_width


      height = nil

      # try attr height - px
      height ||= $1.to_i if flash.attributes['height'].match(/^(\d+)$/)

      # try attr height - %
      height ||= media_width * flash.attributes['height'].to_i / 100 if flash.attributes['height'].match(/^\d+%$/)
      
      # try style height - px
      height ||= $2.to_i if flash.attributes['style'].match(/height:(\s+)?(\d+)px/i)

      # try style height - %
      height ||= (media_width * $2.to_i / 100) if flash.attributes['style'].match(/height:(\s+)?(\d+)%/i)
      
      # finalize with default
      height ||= media_width


      # параметры по-умолчанию для флеша
      embed_params = {'allowfullscreen' => 'false', 'allowscriptaccess' => 'never', 'wmode' => 'opaque'}

      # processing params
      (flash/"//param").each do |param|
        if valid_flash_params.include?(param.attributes['name'].downcase.to_s)
          embed_params[param.attributes['name'].downcase.to_s] = param.attributes['value']
        end
      end
      src = embed_params["movie"]
      src ||= (flash/"//embed[@src]").attr('src') rescue nil

      if src

        # для белых доменов, разрешаем полноэкранный режим
        if allowed_flash_domain?(src)
          embed_params['allowscriptaccess'] = 'never' 
          embed_params['allowfullscreen'] = 'true'
        else
          embed_params['allowscriptaccess'] = 'never' 
          embed_params['allowfullscreen'] = 'false'
        end
        
        embed_params['wmode'] ||= 'opaque'

        # scale height?
        scale_height = true
        scale_height = false if src.include?('prostopleer.com')
      
        if width > media_width
          height = scale_height ? ((media_width / width.to_f) * height.to_f).to_i : height
          width = media_width
        end

        text = "<object width='#{width}' height='#{height}' classid='clsid:d27cdb6e-ae6d-11cf-96b8-444553540000' codebase='http://fpdownload.adobe.com/pub/shockwave/cabs/flash/swflash.cab#version=9,0,0,0'>#{embed_params.map{|name, value| "<param name='#{name}' value='#{value}' >"}.join}<embed pluginspage='http://www.adobe.com/shockwave/download/index.cgi?P1_Prod_Version=ShockwaveFlash' src='#{src}' type='application/x-shockwave-flash' #{embed_params.except('movie').map{|name, value| "#{name}='#{value}'"}.join(" ")} width='#{width}' height='#{height}'></object>"

        if flash.css_path.include?(" p ") || flash.css_path.include?("p:")
          flash.swap(text)
        else
          flash.swap("<p>#{text}</p>")
        end
      else
        flash.swap("<div class='t-entry-warn'>Ошибка: неверные данные во вставляемом коде.</div>")
      end
    end
    
    # remove style attributes
    doc.search('[@style]').remove_attr('style')

    html = auto_link(doc.to_html.gsub(/<p>\s*?<\/p>/mi, ''))

    if link_target
      dd = Hpricot(html.to_s)
      (dd/"//a").each do |a|
        a['target'] = link_target unless a.attributes['href'].blank?
      end
      
      html = dd.to_html
    end

    html
  end

  def allowed_flash_domain?(url)
    domain = URI.parse(url).try(:host).to_s.split(".").reverse[0,2].reverse.join(".") rescue nil
    return false unless domain
    
    flash_whitelist_file = File.join(RAILS_ROOT, 'config', 'flash_whitelist.yml')
    flash_whitelist = YAML.parse_file(flash_whitelist_file).children.map(&:value)
    flash_whitelist.is_a?(Array) && flash_whitelist.include?(domain)
  end

end
