class ApplicationController < ActionController::Base
  filter_parameter_logging :password
  
  # before_filter :prelaunch_megasecrecy

  # меряем производительность только на реальном сайте
  # if RAILS_ENV == 'production'
  #   around_filter do |controller, action|
  #     result = Benchmark.measure { action.call }
  # 
  #     Performance.transaction do
  #       perf = Performance.find_or_initialize_by_controller_and_action_and_day(controller.controller_name, controller.action_name, Time.now.to_date)
  #       perf.increment(:calls)
  #       perf.realtime ||= 0.0
  #       perf.realtime += result.real
  #       perf.stime += result.stime
  #       perf.utime += result.utime
  #       perf.cstime += result.cstime
  #       perf.cutime += result.cutime      
  #       perf.save!
  #     end
  #   end
  # end
  
  include ExceptionNotifiable if RAILS_ENV == 'production'
  include ProductionImages if RAILS_ENV == 'development'
  
  helper :url, :white_list

  # MAIN FILTERS
  attr_accessor   :current_site
  helper_method   :current_site

  attr_accessor   :current_user
  helper_method   :current_user
  
  attr_accessor   :current_service
  helper_method   :current_service
  
  helper_method   :is_admin?

  before_filter :preload_current_service
  before_filter :preload_current_site # loads @current_site
  before_filter :preload_current_user # loads @current_user
  
  protected
    def preload_current_service
      @current_service = Tlogs::Domains::CONFIGURATION.options_for(request.host || 'localhost', request)
    end
  
    def preload_current_site
      @current_site = nil

      url = nil
      if request.host.ends_with?('mmm-tasty.ru')
        url = request.subdomains.first
        
        # перенаправляем на сайт сервиса, если адрес запрещенный
        redirect_to "#{request.protocol}www.mmm-tasty.ru#{request.port == 80 ? '' : ":#{request.port}"}" and return false if User::RESERVED.include?(url)
      elsif request.host == 'localhost'
        url = params[:current_site] if request.path.starts_with?('/users/')
        
        # перенаправляем на сайт сервиса, если адрес запрещенный
        redirect_to "#{request.protocol}#{request.host_with_port}" and return false if User::RESERVED.include?(url)
      end
      
      
      @current_site = User.find_by_url(url, :include => [:tlog_settings, :avatar])
      
      true
    end
  
    def preload_current_user
      return true if @current_user

      # from session
      if session[:user_id]
        @current_user = User.active.find_by_id(session[:user_id])
        # logger.info "user #{@current_user.url} from session (id = #{@current_user.id})" and return true if @current_user
      end

      unless cookies['tsig'].blank?
        id, sig = cookies['tsig'].unpack('m').first.unpack('LZ*')
        user = User.active.find_by_id(id, :conditions => 'is_disabled = 0')
        if user && user.signature == sig
          session[:user_id] = user.id
          @current_user = user
          # logger.info "user #{user.url} from tsig (id = #{user.id})"
        end
      end

      true
    end
    
    # # 
    # def prelaunch_megasecrecy
    #   return true if cookies['megasecret'] == 'v3' || params[:controller] == 'tlog_feed'
    #   
    #   if request.post? && params[:megasecret] == 'lsd'
    #     cookies['megasecret'] = { :value => 'v3', :expires => 1.year.from_now, :domain => request.domain }
    #     redirect_to main_url(:host => "www.mmm-tasty.ru")
    #     return false
    #   end
    #   
    #   render :template => 'globals/prelaunch_megasecrecy', :layout => false
    #   false
    # end

    # Является ли текущий пользователь владельцем сайта
    def is_owner?
      return true if current_user && current_site && current_user.id == current_site.id
      false
    end
    helper_method :is_owner?

    # Фильтр который требует чтобы пользователь был авторизован прежде чем
    #  мог получить доступ к указанной странице
    def require_current_user
      if current_user && current_user.is_a?(User)        
        redirect_to service_path(login_path) and return false if current_user.is_disabled?
        return true
      end
      
      flash[:notice] = 'Вам необходимо зайти чтобы выполнить запрос'
      if request.get?
        session[:redirect_to] = "#{request.protocol}#{request.host_with_port}#{request.request_uri}"
        logger.debug "saving back redirect to: #{session[:redirect_to]}"
      end
      redirect_to service_path(login_path)
      false
    end
    
    def require_current_site
      return true if current_site && current_site.is_a?(User)
      render :template => 'global/tlog_not_found', :layout => false, :status => 404
      false
    end
    
    def is_admin?
      current_user && current_user.is_admin?
    end
    
    def require_admin
      return true if require_current_user && current_user.is_admin?
      
      render :text => 'pemission denied', :status => 403
      return false
    end

    def require_confirmed_current_user
      redirect_to service_path(confirm_path(:action => :required)) and return false if (is_owner? && !current_site.is_confirmed?) || (!current_site && current_user && !current_user.is_confirmed?)
      
      redirect_to service_path(login_path) and return false if current_user && current_user.is_disabled?
      
      true    
    end
    
    def require_confirmed_current_site
      if !current_site.is_confirmed?          
        render_tasty_404("Этот имя занято, но пользователь еще не подтвердил свою регистрацию.<br/>Загляните, пожалуйста, позже.<br/><br/><a href='#{current_service.url}' rel='follow'>&#x2190; вернуться на главную</a>")
        return false
      end
      
      if current_site.is_disabled?
        render_tasty_404("Этот аккаунт заблокирован или удален")
        return false
      end
      
      true
    end

    def current_user_eq_current_site
      return true if current_user && current_site && current_user.id == current_site.id
      
      render(:text => 'permission denied', :status => 403) and return false
    end

    def render_tasty_404(text, options = {})
      options[:layout] ||= '404'
      options[:status] ||= 404
      options[:text] = text
      render options
    end    
    
    
    #
    # URL HELPERS
    #    
    def user_path(user, path = '/')
      host = request.host.gsub(/^www\./, '') # rescue current_service.domain

      # если адрес запрашиваемого сайта есть домен пользователя, тогда возвращаем относительный путь
      if host == user.domain
        path
      else
        user_url(user, path)
      end    
    end
    helper_method :user_path

    def user_url(user, path = '/')
      (current_service.user_url(user.url) + path).gsub(/\/+$/, '')
    end
    helper_method :user_url

    def service_path(path = '/')
      service_url(path)
    end
    helper_method :service_path

    def service_url(path = '/')
      host = request.host.gsub(/^www\./, '') 
      if current_service.domain == host
        path
      else
        current_service.url + path
      end
    end
    helper_method :service_url

    def host_for_tlog(user, options = {})
      user_url(user)
    end
    helper_method :host_for_tlog

    def url_for_tlog(user, options = {})
      page = options.delete(:page) || 0
      fragment = options.delete(:fragment) || nil
      fragment = (page > 0 ? '#' : '/#') + fragment if fragment
      "http://#{host_for_tlog(user, options)}#{page > 0 ? "/page/#{page}" : ''}#{fragment}"
    end
    helper_method :url_for_tlog

    def url_for_entry(entry, options = {})
      is_daylog = current_site.tlog_settings.is_daylog? if current_site
      is_daylog ||= options.delete(:is_daylog)
      user = current_site ? current_site : entry.author

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
          user_url(user, page_path(:page => entry.page_for(current_user)))
        end
      end
    end
    helper_method :url_for_entry
end
