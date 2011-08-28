# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def tasty_error_message_on(object, method, options = {})
    if obj = instance_variable_get("@#{object}")
      id = options.delete(:id) || "#{object}_#{method}"
      content_tag("div",
        content_tag("div",
          (errors = obj.errors.on(method)) ? content_tag("span", errors.is_a?(Array) ? errors.first : errors, :id => "#{id}_error_content") : content_tag("span", '', :id => "#{id}_error_content"),
         :class => 'tip error', :id => "#{id}_error"),
       :class => 'rel');
    else
      ''
    end
  end
  
  # avatar_tag (this is legacy, use userpic_tag)
  #   user
  #   options
  #     :blank
  #     :width
  #     :height
  def avatar_tag(user, options = {})
    blank     = options[:blank] || false

    # backwards compatibility
    empty     = options[:empty] || false
    blank   ||= true if empty && empty.to_sym == :blank

    avatar    = user.avatar
    width     = avatar ? avatar.width : 64
    height    = avatar ? avatar.height : 64

    if (options[:width] && options[:width] < width) || (options[:height] && options[:height] < height)
      w_ratio = (options[:width] && options[:width] > 0) ? options[:width].to_f / width.to_f : 1
      h_ratio = (options[:height] && options[:height] > 0) ? options[:height].to_f / height.to_f : 1
    
      ratio = [w_ratio, h_ratio].min

      width = ratio < 1 ? (width * ratio).to_i : width
      height = ratio < 1 ? (height * ratio).to_i : height
    end

    url = avatar ? image_path(avatar.public_filename) : (blank ? 'noavatar.gif' : nil)

    url ? image_tag(url,
            :class  => classes('avatar', [options[:class], options[:class]]),
            :alt    => user.url,
            :width  => width,
            :height => height
          ) : ''
  end
  
  # new way to embed userpics (succeeds avatar_tag)
  def userpic_tag(user, options = {})
    # fallback to legacy code while we do not have all users migrated to the new rules
    return avatar_tag(user, options) unless user.userpic?
    
    blank     = options[:blank] || false

    # backwards compatibility
    empty     = options[:empty] || false
    blank   ||= true if empty && empty.to_sym == :blank
    
    style     = \
      case options[:width] || 64
        when 0..16 then :thumb16
        when 16..32 then :thumb32
        when 32..64 then :thumb64
        when 64..128 then :thumb128
        else :thumb64
      end

    width     = user.userpic.width(style)
    height    = user.userpic.height(style)

    if (options[:width] && options[:width] < width) || (options[:height] && options[:height] < height)
      w_ratio = (options[:width] && options[:width] > 0) ? options[:width].to_f / width.to_f : 1
      h_ratio = (options[:height] && options[:height] > 0) ? options[:height].to_f / height.to_f : 1

      ratio = [w_ratio, h_ratio].min

      width = ratio < 1 ? (width * ratio).to_i : width
      height = ratio < 1 ? (height * ratio).to_i : height
    end

    # content_tag(:div, 'pro', :class => 't-avatar-badge-pro') + 
    image_tag(image_path(user.userpic.url(style)),
        :class  => classes('avatar', [options[:class], options[:class]]),
        :alt    => user.url,
        :width  => width,
        :height => height
      )
  end
  
  def flash_div
    [:bad, :good].each do |key|
      if flash && flash[key]
        flash.discard key
        return <<-END
<div id='flash_holder'><table id='flash' onclick="new Effect.Fade ('flash', { duration: 0.3, afterFinish: function() { Element.remove('flash_holder'); } } );">
  <tr>
    <td id='flash_message' class='#{key.to_s}'>
      <p>#{CGI::escapeHTML(flash[key])}</p>
    </td>
  </tr>
</table></div>
END
      end
    end
    ""
  end
  
  # classes is to set css-classes or other attributes conditionally
  # classes("class-without-conditions", ["logged-class", logged_in?], "third-class-without-conditions")
  def classes(*pairs)
    glued_classes = []
    pairs.each do |pair| 
      next if pair.blank?
      arr = Array(pair)
      raise ArgumentError, "css_class or [css_class, condition] are expected (got #{pair.inspect})" if arr.size.zero? || arr.size > 2
      glued_classes << arr[0] if arr[1] || arr.size == 1
    end
    glued_classes.any? ? glued_classes.join(" ") : nil
  end
  
  def audio_player_id
    @audio_player_id ||= 0
    @audio_player_id += 1
    "#{@audio_player_id}"
  end
  
  def application_title
    content_tag(:title, [h(current_site ? h(current_site.url) : current_service.name), strip_tags(@title)].reject(&:blank?).join(' – ')) if @title
  end
  
  def link_to_tlog(user, options = {}, html_options = nil)
    link_to_tlog_if(true, user, options, html_options)
  end
  
  def link_to_tlog_if(condition, user, options = {}, html_options = nil)
    options ||= {}
    html_options ||= {}

    username = case options.delete(:link) || :url
                  when :userpic
                    userpic_tag(user, options)
                  when :username
                    CGI::escapeHTML(user.username)
                  else
                    user.is_a?(String) ? CGI::escapeHTML(user) : user.url
                end

    css_class = html_options.delete(:class) || ''
    css_class += ' no_visited'
    html_options.merge!({ :class => css_class.strip })
    link_to_if condition, username, user_url(user), html_options
  end
  
  def resized_image_path(src, width)
    return src if !current_service || !current_service.is_mobile?

    url = URI.parse(src) rescue nil

    # skip already rewritten (should not happen though)
    return src if url.nil? || url.host.nil? || url.host =~ /assets[0-3]\.(mmm-tasty\.ru|tlogs\.ru)\/\d{3}\//

    sig   = Digest::SHA1.hexdigest("w:#{width}/u:#{url.to_s}/s:keepitreal")[0..7]
    path  = [width, sig, src].join('/')

    # pick an asset
    asset_av = [0, 1, 3]
    asset_id = asset_av[sig.hash % 3]
    asset = "http://assets#{asset_id}.mmm-tasty.ru"
    
    [asset, path].join('/')
  end

  def mark(keyword)
    Entry.find_by_sql("/* #{keyword} */ SELECT id FROM entries WHERE id = 0")
  end
  
  def paginate(pageable, options = {})
    render :partial => 'globals/pagination', :locals => options.merge(:pageable => pageable)
  end
  
  def infinite_paginate(page, options = {})
    render :partial => 'globals/infinite_pagination', :locals => options.merge(:page => page) if page
  end
  
  # escape and truncate html attribute
  # options are for truncate() call, e.g. :length
  def h_attr(text, options = {})
    truncate(strip_tags(text), { :length => 64 }.merge(options)).gsub(/(\r\n|\r|\n)/, ' ').tr('"', "&quot;").tr('\'', "&quot;")
  end
  
  def timeago(time, options = {})
    options[:class] ||= 'timeago'
    content_tag(:abbr, Russian::strftime(time, '%d %B %Y в %H:%M'), options.merge(:title => time.getutc.iso8601))
  end
  
  def current_controller_class
    't-controller-' + params[:controller].gsub('/', '-')
  end
  
  def current_action_class
    't-action-' + params[:action]
  end
  
  def say_time_in_words(time)
    distance    = (time - Time.now).round
    in_minutes  = (distance / 1.minute).round.abs
    
    if distance > 0
      # future
      if distance <= 1.hour
        # через час или через 30 минут
        if distance < 5.minutes
          "через пару минут"
        elsif distance <= 1.hour
          "через #{in_minutes} #{Russian::p(in_minutes, "минуту", "минуты", "минут")}"
        end
      else
        # точное время
        if time.day == Time.now.day && distance < 1.day
          Russian::strftime(time, "в %H:%M")
        elsif time.day == Time.now.tomorrow.day && distance < 1.day && time.hour < 4
          # поздно ночью
          Russian::strftime(time, "ночью в %H:%M")
        elsif time.day == Time.now.tomorrow.day
          Russian::strftime(time, "завтра в %H:%M")
        else
          Russian::strftime(time, "%e %B в %H:%M")
        end
      end
    else
      distance = distance.abs
      if distance < 5.minutes
        "пару минут назад"
      elsif distance <= 1.hour
        "#{in_minutes} #{Russian::p(in_minutes, "минуту", "минуты", "минут")} назад"
      else
        # точное время
        if time.day == Time.now.day && distance < 1.day
          Russian::strftime(time, "сегодня в %H:%M")
        elsif time.day == Time.now.yesterday.day
          Russian::strftime(time, "вчера в %H:%M")
        elsif time.year == Time.now.year
          Russian::strftime(time, "%e %B в %H:%M")
        else
          Russian::strftime(time, "%e %B %Y в %H:%M")
        end
      end
    end
  end
  
end
