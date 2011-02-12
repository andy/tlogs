module MainHelper
  #
  # <%= menu_item "Тип тлога", :blah, %w(blah index gah)
  # <%= menu_item
  def menu_item(name, url, selected_action = nil)
    link_options = {}
    action = url.to_s.split('/').last
    url = main_url(:action => url.to_s) unless url.to_s.starts_with?('http://')
    selected_action = action if selected_action.nil?

    selected_action = selected_action.to_a unless selected_action.is_a?(Array)
    link_options[:class] = 'selected' if selected_action.include?(params[:action]) ||
        selected_action.include?([params[:controller], params[:action]].join('/')) ||
        selected_action.include?(params[:controller] + '/*')
        
    content_tag :li, link_to(name, url, link_options)
  end
  
  def updated_comments_count(entry, views)
    v = views.select { |v| v.id == entry.id }.try(:first)

    txt = ''

    if v
      if (v.last_comment_viewed && v.last_comment_viewed > 0 && v.last_comment_viewed != v.comments_count)
        txt = "#{v.last_comment_viewed}+#{v.comments_count - v.last_comment_viewed}"
      elsif (current_user && !v.last_comment_viewed && v.comments_count > 0)
        txt = "+#{v.comments_count}"
      else
        txt = entry.comments_count
      end
    else
      txt = entry.comments_count
    end
    
    txt
  end
  
end
