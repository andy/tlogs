module SettingsHelper
  #
  # <%= menu_item "Тип тлога", :blah, %w(blah index gah)
  # <%= menu_item
  def menu_item(name, url, selected_action = nil, &block)
    link_options = {}
    action = url.to_s.split('/').last
    url = user_url(current_user, settings_path(:action => url.to_s)) unless url.to_s.starts_with?('http://') || url.to_s.starts_with?('/')
    selected_action = action if selected_action.nil?

    selected_action = selected_action.to_a unless selected_action.is_a?(Array)
    link_options[:class] = 'selected' if selected_action.include?(params[:action]) || selected_action.include?([params[:controller], params[:action]].join('/'))

    if block_given?
      content = capture(&block)
      concat(content_tag(:li, link_to(name, url, link_options) + content_tag(:ul, content)))
    else
      content_tag :li, link_to(name, url, link_options)
    end
  end
  
  # sidebar_check_box(:is_open)
  # sidebar_check_box(:hide_tags)
  # sidebar_check_box(:hide_search)
  # sidebar_check_box(:hide_calendar)
  def sidebar_check_box(name, options = {})
    options[:onclick] = "new Ajax.Request('#{user_url(current_site, '/settings/sidebar/toggle_checkbox')}', { asynchronous: true, evalScripts: true, parameters: { name: '#{name}', authenticity_token: '#{form_authenticity_token}' } } ); return false;"
    check_box_tag "sidebar_#{name}", '1', !current_site.tlog_settings.send("sidebar_#{name}?"), options
  end
end
