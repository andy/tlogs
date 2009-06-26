module UrlHelper
  #
  # URL HELPERS
  #
  def get_current_service
    @current_service || current_service
  end
  
  def get_current_site
    @current_site || nil
  end
  
  def get_current_user
    @current_user || nil
  end
  
  def get_request
    request || nil
  end
  
  
  def user_path(user, path = '/')
    host = request.host.gsub(/^www\./, '') # rescue current_service.domain

    # если адрес запрашиваемого сайта есть домен пользователя, тогда возвращаем относительный путь
    if host == user.domain
      path
    else
      user_url(user, path)
    end    
  end

  def user_url(user, path = '/')
    (get_current_service.user_url(user.url) + (path || '/')).gsub(/\/+$/, '')
  end

  def service_path(path = '/')
    service_url(path)
  end

  def service_url(path = '/')
    if get_request
      host = request.host.gsub(/^www\./, '') 
      if get_current_service.domain == host
        path
      else
        get_current_service.url + path
      end
    else
      get_current_service.url + path
    end
  end

  def host_for_tlog(user, options = {})
    user_url(user)
  end

  def url_for_tlog(user, options = {})
    page = options.delete(:page) || 0
    fragment = options.delete(:fragment) || nil
    fragment = ((page.to_i > 0 || get_current_service.is_inline?) ? '#' : '/#') + fragment if fragment
    "http://#{host_for_tlog(user, options)}#{page.to_i > 0 ? "/page/#{page}" : ''}#{fragment}"
  end

  def tlog_url_for_entry(entry, options = {})
    is_daylog = get_current_site.tlog_settings.is_daylog? if get_current_site
    is_daylog ||= options.delete(:is_daylog)
    user = get_current_site ? get_current_site : entry.author

    if is_daylog
      date = entry.created_at.to_date
      options[:host] = host_for_tlog(user, options)
      options[:year] = date.year
      options[:month] = date.month
      options[:day] = date.mday
      fragment = options.delete(:fragment) || nil
      fragment = ((date == Date.today) ? '/#' : '#') + fragment if fragment 
      (date == Date.today) ? user_url(user, fragment) : user_url(user, day_path(options) + (fragment || ''))
    else 
      if entry.is_anonymous?
        user_url(user, anonymous_entries_path)
      elsif entry.is_private?
        user_url(user, private_entries_path)
      else
        user_url(user, page_path(:page => entry.page_for(get_current_user)))
      end
    end
  end
end