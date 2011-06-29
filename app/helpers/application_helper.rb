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
  
  # >> avatar_image_tag(current_user, :empty => false)       DEFAULT
  # >> avatar_image_tag(current_user, :empty => :blank)
  def avatar_image_tag(user=nil, options = {})
    user    ||= current_user
    avatar    = user.avatar
    empty     = options.delete(:empty) || false
    if avatar
      width = avatar.width
      height = avatar.height

      if options[:width] && options[:width] < width
        ratio = options[:width] > 0 ? options[:width].to_f / width.to_f : 1

        # пересчитываем
        width = ratio < 1 ? (width * ratio).to_i : width
        height = ratio < 1 ? (height * ratio).to_i : height
      end
      
      "<img src='#{image_path avatar.public_filename}' class='avatar' style='width: #{width}px; height: #{height}px' />"
    elsif empty
      case empty
      when :blank, 'blank'
        image_tag 'noavatar.gif', :class => 'avatar'
      end
    end
  end
  
  def flash_div
    [:bad, :good].each do |key|
      if flash[key]
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
  
  def audio_player_id
    @audio_player_id ||= 0
    @audio_player_id += 1
    "#{@audio_player_id}"
  end
  
  def link_to_tlog(user, options = {}, html_options = nil)
    link_to_tlog_if(true, user, options, html_options)
  end
  
  def link_to_tlog_if(condition, user, options = {}, html_options = nil)
    options ||= {}
    html_options ||= {}

    username = case options.delete(:link) || :url
                  when :avatar
                    avatar_image_tag(user, options)
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
  
  def mark(keyword)
    Entry.find_by_sql("/* #{keyword} */ SELECT id FROM entries WHERE id = 0")
  end
  
  def paginate(pageable, options = {})
    render :partial => 'globals/pagination', :locals => options.merge(:pageable => pageable)
  end
  
  def timeago(time, options = {})
    options[:class] ||= 'timeago'
    content_tag(:abbr, Russian::strftime(time, '%d %B %Y в %H:%M'), options.merge(:title => time.getutc.iso8601))
  end
  
  def say_schedule_in_words(time)
    distance    = (time - Time.now).round
    in_minutes  = (distance / 1.minute).round
    
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
          Russian::strftime(time, "%d %B в %H:%M")
        end
      end
    else
      # past
      "уже была"
    end
  end
end
