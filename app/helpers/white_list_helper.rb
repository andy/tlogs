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
    white_list_html_with_rescue(text, :flash_width => 420)
  end

  
  def white_list_entry(text, options = {})
    white_list_html_with_rescue(text)
  end
  
  def white_list_sidebar(text, options = {})
    white_list_html_with_rescue(text, :link_target => '_blank')
  end
  
  def white_list_comment(text)
    white_list_html_with_rescue(text, :flash_width => 290)
  end
  
  def white_list_html_with_rescue(html, options = {})
    begin
      white_list_html(html, options)
    rescue Exception => ex
      logger.error "> Failed to render the following content"
      logger.error html
      logger.error "> Exception was: #{ex.message}"
      
      "внутреняя ошибка сервера"
    end
  end

  def white_list_html(html, options = {})
    require 'hpricot'

    valid_flash_params = %w(movie allowfullscreen allowscriptaccess wmode flashvars)
    valid_iframe_params = %w(title width height src frameborder allowfullscreen alt)
    
    html.gsub!('&amp;', '&')
    html.gsub!('amp;', '')
    
    flash_width = options[:flash_width] || 400
    link_target = options[:link_target] || nil
    
    doc = Hpricot(simple_tasty_format(html), :fixup_tags => true)

    # Делаем сканирование элементов
    allowed_tags = Set.new(%w(a b i s br img p strong em ul ol li h1 h2 h3 h4 h5 h6 div object iframe param))
    allowed_attributes = Set.new(%w(class id href alt src width height title border tag name value style))
    
    doc = Hpricot(sanitize(doc.to_html, :tags => allowed_tags, :attributes => allowed_attributes), :fixup_tags => true)

    # Удаляем пустые параграфы
    # (doc/"//p[text()='']").remove    
    
    (doc/"//p").each do |paragraph|
      next if paragraph.children.blank?

      paragraph.children.select { |e| e.text? }.each do |text|
        new_text = auto_link(text.to_html)

        # [andy] -> ссылка на пользователя
        new_text.gsub!(/(\[([a-z0-9_-]{2,20})\])/) do
          user = User.find_by_url($2)
          user ? "<a href='#{user_url(user)}' class='entry_tlog_link'>#{user.url}</a>" : $1
        end

        # @andy -> ссылка на пользователя
        new_text.gsub!(/(\@([a-z0-9_-]{2,20}))/) do
          user = User.find_by_url($2)
          user ? "<a href='#{user_url(user)}' class='entry_tlog_link'>@#{user.url}</a>" : $1
        end

        text.swap(new_text) unless new_text.blank?        
      end
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
        
        width = (attrs['width'] && attrs['width'].ends_with?('%')) ? (flash_width * attrs['width'].to_i / 100) : (attrs['width'].to_i || flash_width)
        # width  = attrs['width'].to_i || flash_width
        height = attrs['height'].to_i || flash_width

        if width > flash_width
          attrs['height'] = scale_height ? ((flash_width / width.to_f) * height.to_f).to_i : height
          attrs['width']  = flash_width
        end
        
        iframe.swap content_tag(:iframe, nil, attrs)
      else
        iframe.swap("<p>Извините, но вставлять такой код запрещено.</p>")
      end
    end
    
    
    (doc/"//object").each do |flash|
      width = nil
      
      # try attr width - px
      width ||= $1.to_i if flash.attributes['width'].match(/^(\d+)$/)

      # try attr width - %
      width ||= flash_width * flash.attributes['width'].to_i / 100 if flash.attributes['width'].match(/^\d+%$/)

      # try style width - px
      width ||= $2.to_i if flash.attributes['style'].match(/width:(\s+)?(\d+)px/i)

      # try style width - %
      width ||= (flash_width * $2.to_i / 100) if flash.attributes['style'].match(/width:(\s+)?(\d+)%/i)

      # finalize with default
      width ||= flash_width


      height = nil

      # try attr height - px
      height ||= $1.to_i if flash.attributes['height'].match(/^(\d+)$/)

      # try attr height - %
      height ||= flash_width * flash.attributes['height'].to_i / 100 if flash.attributes['height'].match(/^\d+%$/)
      
      # try style height - px
      height ||= $2.to_i if flash.attributes['style'].match(/height:(\s+)?(\d+)px/i)

      # try style height - %
      height ||= (flash_width * $2.to_i / 100) if flash.attributes['style'].match(/height:(\s+)?(\d+)%/i)
      
      # finalize with default
      height ||= flash_width


      # параметры по-умолчанию для флеша
      embed_params = {'allowfullscreen' => 'false', 'allowscriptaccess' => 'never'}

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
        embed_params['allowfullscreen'] = 'true' if allowed_flash_domain?(src)

        # scale height?
        scale_height = true
        scale_height = false if src.include?('prostopleer.com')
      
        if width > flash_width
          height = scale_height ? ((flash_width / width.to_f) * height.to_f).to_i : height
          width = flash_width
        end

        text = "<object width='#{width}' height='#{height}'>#{embed_params.map{|name, value| "<param name='#{name}' value='#{value}' >"}.join}<embed src='#{src}' type='application/x-shockwave-flash' #{embed_params.except('movie').map{|name, value| "#{name}='#{value}'"}.join(" ")} width='#{width}' height='#{height}'></object>"

        if flash.css_path.include?(" p ") || flash.css_path.include?("p:")
          flash.swap(text)
        else
          flash.swap("<p>#{text}</p>")
        end
      else
        flash.swap("Ошибка: неверные данные во вставляемом коде.")
      end
    end
    
    html = auto_link(doc.to_html.gsub(/<p>\s*?<\/p>/mi, ''))
  
  
    if link_target
      doc = Hpricot(html)
      (doc/"//a").each do |a|
        a['target'] = link_target unless a.attributes['href'].blank?
      end
      
      html = doc.to_html
    end

    # Делаем сканирование элементов (same as above, without style)
    allowed_tags = Set.new(%w(a b i s br img p strong em ul ol li h1 h2 h3 h4 h5 h6 div object iframe param))
    allowed_attributes = Set.new(%w(class id href alt src width height title border tag name value))        

    doc = Hpricot(sanitize(html, :tags => allowed_tags, :attributes => allowed_attributes), :fixup_tags => true)    
    doc.to_html
  end

  def allowed_flash_domain?(url)
    domain = URI.parse(url).try(:host).to_s.split(".").reverse[0,2].reverse.join(".") rescue nil
    return false unless domain
    
    flash_whitelist_file = File.join(RAILS_ROOT, 'config', 'flash_whitelist.yml')
    flash_whitelist = YAML.parse_file(flash_whitelist_file).children.map(&:value)
    flash_whitelist.is_a?(Array) && flash_whitelist.include?(domain)
  end

end
