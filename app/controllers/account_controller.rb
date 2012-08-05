class AccountController < ApplicationController
  before_filter :require_current_user, :only => [:logout, :rename, :identity, :confirmation_required]
  before_filter :redirect_home_if_current_user, :only => [:index, :login, :signup, :openid_verify]
  before_filter :require_confirmed_current_user, :except => [:logout]

  protect_from_forgery :only => [:login, :logout, :rename, :lost_password, :recover_password, :signup, :update_url_status]

  helper :settings

  def index
    redirect_to service_path(login_path)
  end
  
  # авторизуем пользователя либо по openid, либо по паре имя/пароль
  def login
    if request.post?
      redirect_to service_path(login_path) and return unless params[:user]
      
      @user = User.authenticate(params[:user][:email], params[:user][:password])
      if @user.nil?
        # keep email
        @user = User.new :email => params[:user][:email]
        if params[:user][:email].is_openid?
          flash[:bad] = 'Пользователь с таким адресом не найден'
        else
          user = User.find_by_email(params[:user][:email])
          if user && user.is_disabled?
            flash[:bad] = 'Аккаунт заблокирован'
          else
            flash[:bad] = 'Неправильный логин или пароль'
          end
        end
      # openid пользователь логинится через openid...
      elsif @user.is_openid? && params[:user][:email].is_openid?
          login_with_openid @user.openid
      # иначе, даже если это openid пользователь - авторизуем по емейлу
      else
        @user.log nil, :login, "авторизовался на сайте", nil, request.remote_ip
        login_user @user, { :remember => @user.email, :redirect_to => service_path(params[:ref]) }
      end
    else
      @user = User.new :email => cookies[:l]

      session[:r] = params[:ref] || request.env['HTTP_REFERER'] if params[:noref].nil?
    end
  end

  # переименовать аккаунт
  def rename
    if request.post?
      @user = User.find(current_user.id)
      @user.url = params[:user][:url]
      @user.valid?
      
      if !@user.errors.on("url")
        @user.update_attribute(:url, @user.url)
        
        @user.log nil, :rename, "@#{current_user.url} изменил адрес на @#{@user.url}", nil, request.remote_ip
        
        @user.rename! if params['remove_subscribers'] && params['remove_subscribers'] == '1'
        
        current_user.url = @user.url
        flash[:good] = 'Прекрасно! Адрес вашего тлога изменен'
      else
        flash[:bad] = 'Не удалось изменить адрес вашего тлога'
      end
    else
      @user = current_user
    end
    render :layout => 'settings'
  end

  # потерянный пароль
  def lost_password
    if request.post?
      user   = nil
      user   = User.find_by_email params[:email] unless params[:email].blank?
      user ||= User.find_by_url params[:url] unless params[:url].blank?
      if user && user.email && user.is_confirmed? && !user.is_disabled?
        # бывает когда пароль не установлен и при этом нет openid
        if user.password.blank?
          user.password = SecureRandom.hex(8)
          user.save(false)
        end        
        
        if user.crypted_password
          user.log nil, :recover_password, "запросил восстановление пароля (#{user.email})", nil, request.remote_ip
          Emailer.deliver_lost_password(current_service, user)
          flash[:lost_user_id] = user.id
          redirect_to :action => 'lost_password_sent'
        else
          flash[:bad] = 'У Вас не установлен пароль'
        end
      elsif user && user.is_disabled?
        flash[:bad] = 'Аккаунт, привязанный к этому адресу заморожен или удален. С вопросом о восстановлении обратитесь, пожалуйста, в службу поддержки.'
      elsif user && !user.is_confirmed?
        flash[:bad] = 'К сожалению, ваш аккаунт не подтвержден. Обратитесь, пожалуйста, в службу поддержки.'
      else
        flash[:bad] = 'К сожалению мы не смогли найти указанного вами пользователя'
      end
    else
      @email = current_user.email if current_user && current_user.email
    end
  end
  
  def recover_password
    @user = User.active.find(params[:user_id])
    if @user && @user.recover_secret == params[:secret]
      if request.post?
        @user.password = params[:user][:password]
        if !@user.password.blank? && @user.save
          @user.log nil, :recover_password, "сменил пароль", nil, request.remote_ip
          flash[:good] = 'Ваш пароль был успешно изменен'
          redirect_to service_url(login_path(:noref => true))
        else
          @user.errors.add :password, 'Вы забыли заполнить пароль!' if @user.password.blank?
          flash[:bad] = 'Извините, но ваш пароль не удовлетворяет требованиям безопасности. Попробуйте еще раз'
        end
      end
    else
      
    end
  end
  
  # показывается когда мы действительно высылаем какой-то текст
  def lost_password_sent
    @user = nil
    @user = User.active.find(flash[:lost_user_id]) if flash[:lost_user_id]
  end
  
  # выходим из системы
  def logout
    redirect_to service_url and return unless request.post?

    cookies.delete current_service.is_mobile? ? :tm : :t, :domain => current_service.cookie_domain
    cookies.delete :s, :domain => current_service.cookie_domain
    
    reset_session
    
    respond_to do |wants|
      # wants.mobile do
      #   Rails.logger.debug "wants mobile"
      #   render :json => true
      # end
      wants.html do
        if params[:p] && params[:p] == 'false'
          redirect_to(:back) rescue redirect_to(service_url)
        else
          redirect_to service_url
        end        
      end
      wants.js do
        render :update do |page|
          if params[:p] && params[:p] == 'false'
            page.call 'window.location.reload'
          else
            page << "window.location.href = #{service_url.to_json};"
          end
        end
      end
    end
  end
  
  def eula
    @title = 'Пользовательское соглашение с сервисом Тейсти'
  end

  # регистрация, для новичков
  def signup
    @invitation = Invitation.revokable.find_by_code params[:code]
    
    render :action => 'signup_wall' and return unless @invitation
    
    if request.post?
      @user = User.new :email => @invitation.email, :password => params[:user][:password], :url => params[:user][:url], :openid => nil, :eula => params[:user][:eula]
    
      # проверяем на левые емейл адреса
      @user.errors.add(:email, 'извините, но выбранный вами почтовый сервис находится в черном списке') if @user.email.any? && Disposable::is_disposable_email?(@user.email)
      
      @user.errors.add(:password, 'пожалуйста, укажите пароль') if @user.password.blank?

      @user.settings = {}
      @user.is_confirmed = true
      # @user.update_confirmation!(@user.email)
      @user.save if @user.errors.empty?
      if @user.errors.empty?
        @user.log @invitation.user, :signup, "@#{@user.url} зарегистрировался по приглашению", nil, request.remote_ip
        Emailer.deliver_signup(current_service, @user)
        @invitation.update_attribute(:invitee_id, @user.id)

        login_user @user, :remember => @user.email, :redirect_to => user_url(@user)
      else
        flash[:bad] = 'При регистрации произошли какие-то ошибки'
      end
    else
      @user = User.new :email => @invitation.email
    end
  end
  
  # authorize through vk, http://vk.com/developers.php?oid=-1&p=VK.Auth
  def foreign
    vk_valid_fields = %w(expire mid secret sig sid)
    vk_opts         = ::SETTINGS[:social]['vk'].symbolize_keys
    cookie_name     = "vk_app_#{vk_opts[:app_id]}"
    
    # verify that we get auth cookie
    redirect_to :action => 'signup' and return unless
      cookies.has_key? cookie_name

    # get session attributes
    vk_sess         = Rack::Utils.parse_nested_query(cookies[cookie_name]) rescue {}
    
    # validate session - check that all and only these fields are present
    foreign_error("Извините, но ваша кука — левая!") and return unless
      vk_valid_fields.sort == vk_sess.keys.sort
    
    # verify signature
    vk_sig          = vk_sess.slice(*(vk_valid_fields - ['sig'])).sort.map { |h| h.join('=') }.join + vk_opts[:secret]
    
    foreign_error("Извините, но ваша кука — ненастоящая!") and return unless
      Digest::MD5.hexdigest(vk_sig) == vk_sess['sig']
    
    # verify expiration that session is still valid
    foreign_error("Извините, но время вашей сессии истекло.") and return unless
      vk_sess['expire'].to_i > Time.now.to_i

    #
    # at this point, vk session is valid and can be trused
    #
    foreign_error("Извините, но этот аккаунт ВКонтакте уже использовался для регистрации.") and return if
      User.find_by_vk_id(vk_sess['mid'])

    
    if request.post?
      User.transaction do
        foreign_error("Извините, но этот аккаунт ВКонтакте уже использовался для регистрации.") and return if
          User.find_by_vk_id(vk_sess['mid'])
        
        @user = User.new :email => params[:user][:email], :password => params[:user][:password], :url => params[:user][:url], :eula => params[:user][:eula]
      
        # проверяем на левые емейл адреса
        @user.errors.add(:email, 'извините, но выбранный вами почтовый сервис находится в черном списке') if @user.email.any? && Disposable::is_disposable_email?(@user.email)
      
        @user.errors.add(:password, 'пожалуйста, укажите пароль') if @user.password.blank?

        @user.settings      = {}
        @user.vk_id         = vk_sess['mid']
        @user.is_confirmed  = false
        @user.update_confirmation! @user.email
      
        @user.save if @user.errors.empty?
        if @user.errors.empty?
          @user.log nil, :signup, "зарегистрировался через ВКонтакте http://vk.com/id#{@user.vk_id}", nil, request.remote_ip
          Emailer.deliver_foreign(current_service, @user)
        
          login_user @user, :remember => @user.email, :redirect_to => user_url(@user)
        else
          flash[:bad] = 'При регистрации произошли какие-то ошибки'
        end
      end
    else
      @user = User.new
    end
  end

  
  # возвращает статус для имени пользователя
  def update_url_status
    url = params[:url] || ''
    user = User.new :url => url
    user.valid?
    render :update do |page|
      page << "if ( $('user_url').value == '' ) {"
        page.call :clear_error_message_on, 'user_url'
      page << "} else if ( $('user_url').value == '#{params[:url].to_s.escape_javascript}') {"
      if user.errors.on "url"
        page.call :error_message_on, 'user_url', user.errors.on("url")
      else
        page.call :error_message_on, 'user_url', "этот адрес свободен", true
      end
      page << '}'
    end
  end
  
  def openid_verify
    return_to = service_url(account_path(:only_path => false, :action => 'openid_verify'))
    parameters = params.reject{|k,v| request.path_parameters[k] }
    oresponse = openid_consumer.complete parameters, return_to

    case oresponse.status
    when OpenID::Consumer::SUCCESS

      openid = oresponse.endpoint.claimed_id
      
      # если пользователь с таким openid уже сущствует то все что нам нужно сделать
      # - это залогинить его в систему 
      # в противном случае мы выставляем :openid и перебрасываем на signup
      user = User.find_by_openid openid
      if user
        flash[:good] = 'Вы авторизовались на сайте'
        login_user user, :remember => openid
      else
        flash[:bad] = 'Извините, но регистрация через openid временно отключена.'
        render :action => 'signup'
        
        # session[:openid] = openid
        # @user = User.new :openid => openid, :url => session[:user_url], :email => nil, :password => nil
        # @user.is_confirmed = true
        # if @user.save
        #   flash[:good] = 'Поздравляем, вы зарегистрировались!'
        #   login_user @user, :remember => openid
        # else
        #   render :action => 'signup'
        # end
      end
      return

    when OpenID::Consumer::FAILURE
      if oresponse.endpoint.claimed_id
        flash[:bad] = "Verification of #{oresponse.endpoint.claimed_id} failed."
      else
        flash[:bad] = 'Не получилось подтвердить аккаунт' # 'Verification failed.'
      end

    when OpenID::Consumer::CANCEL
      flash[:bad] = 'Подтверждение отменено' # 'Verification cancelled.'

    when OpenID::Consumer::SETUP_NEEDED
    else
      flash[:bad] = 'Непонятный ответ от OpenID сервера' # 'Unknown response from OpenID server.'
    end

    redirect_to service_url(login_path)
  end
    
  private
    def login_with_openid(openid)
      begin
        oid_req = openid_consumer.begin openid
      rescue OpenID::OpenIDError => e
        # NOTE: flash[:bad] is treated as unsafe, so this is okay
        flash[:bad] = e.to_s
        redirect_to service_url(signup_path)
        return
      end
      
      # success
      return_to = account_url(:action => 'openid_verify')
      trust_root = account_url

      unless User.find_by_openid(oid_req.endpoint.claimed_id)
        sreg_request = OpenID::SReg::Request.new        
        sreg_request.request_fields(['nickname', 'fullname', 'email', 'dob', 'gender'], false) # optional
        oid_req.add_extension(sreg_request)
        # oid_req.add_extension_arg('sreg', 'optional', 'nickname,fullname,email,dob,gender')
      end

      redirect_to oid_req.redirect_url(trust_root, return_to, false)
    end

    # Get the OpenID::Consumer object.
    def openid_consumer
      # create the OpenID store for storing associations and nonces,
      # putting it in your app's db directory
      # you can also use database store.
      store_dir = Pathname.new(RAILS_ROOT).join('db').join('openid-store')
      store = OpenID::Store::Filesystem.new(store_dir)

      return OpenID::Consumer.new(session, store)
    end
    
    def login_user(user, options = {})
      l_key = current_service.is_mobile? ? 'lm' : 'l'
      cookies[l_key.to_sym] = {
          :value => options[:remember],
          :expires => 1.year.from_now
        } if options[:remember]

      session[:u] = user.id
      update_cookie_sig!(user)
      session[:ip] = request.remote_ip
      

      # result redirect
      if current_service.is_mobile?
        redirect_to '/'
      else
        redirect = options[:redirect_to]
        if redirect.blank? && session[:r]
          redirect = session[:r]
          redirect = user_url(user, redirect) if redirect && redirect.starts_with?('/')
          session[:r] = nil
        end
        redirect_to redirect || user_url(user)
      end
    end
    
    def redirect_home_if_current_user
      redirect_to user_url(current_user) and return false if current_user
      true
    end
    
    def foreign_error message
      @message = message
      render :action => 'foreign_error'
    end
end
