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
          flash[:bad] = 'Неправильный логин или пароль'
        end
      # openid пользователь логинится через openid...
      elsif @user.is_openid? && params[:user][:email].is_openid?
          login_with_openid @user.openid
      # иначе, даже если это openid пользователь - авторизуем по емейлу
      else
        cookies[:t] = {
            :value => [@user.id, @user.signature].pack('LZ*').to_a.pack('m').chop,
            :expires => 1.year.from_now,
            :domain => current_service.cookie_domain
          }
        login_user @user, :remember => @user.email
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
      user   = User.active.find_by_email params[:email] unless params[:email].blank?
      user ||= User.active.find_by_url params[:url] unless params[:url].blank?
      if user
        if user.crypted_password
          Emailer.deliver_lost_password(current_service, user)
          flash[:lost_user_id] = user.id
          redirect_to :action => 'lost_password_sent'
        else
          flash[:bad] = 'У Вас не установлен пароль'
        end
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

    cookies.delete :t, :domain => current_service.cookie_domain
    cookies.delete :s, :domain => current_service.cookie_domain
    reset_session
    
    respond_to do |wants|
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

  # регистрация, для новичков
  def signup
    @allow_by_remote_addr = false

    # look up remote address
    @ipinfo = Ipgeobase.lookup(request.remote_ip)
    @allow_by_remote_addr = true if @ipinfo && %w(Пермь пермь Тверь тверь).include?(@ipinfo[:city])
    
    if @allow_by_remote_addr || ([6,0].include?(Date.today.wday) && [22, 23, 24].include?(Time.now.hour)) || ([1,0].include?(Date.today.wday) && [0, 1, 2, 3, 4].include?(Time.now.hour))
      if request.post?
        email_or_openid = params[:user][:email]
        if email_or_openid.is_openid?
          # запоминаем сайт который он выбрал и подтверждаем openid
          session[:user_url] = params[:user][:url]
          login_with_openid email_or_openid
        else
          @user = User.new :email => email_or_openid, :password => params[:user][:password], :url => params[:user][:url], :openid => nil
        
          # проверяем на левые емейл адреса
          @user.errors.add(:email, 'извините, но выбранный вами почтовый сервис находится в черном списке') if @user.email.any? && Disposable::is_disposable_email?(@user.email)
    
          @user.settings = {}
          @user.is_confirmed = false
          @user.update_confirmation!(@user.email)
          @user.save if @user.errors.empty?
          if @user.errors.empty?
            Emailer.deliver_signup(current_service, @user)
            login_user @user, :remember => @user.email, :redirect_to => service_url(confirm_path(:action => :required))
          else
            flash[:bad] = 'При регистрации произошли какие-то ошибки'
          end
        end
      else
        @user = User.new
        @user.email = params[:openid] if params[:openid]
      end
    else
      render :action => 'signup_disabled'
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
      cookies[:l] = {
          :value => options[:remember],
          :expires => 1.year.from_now
        } if options[:remember]

      session[:u] = user.id

      # result redirect
      redirect = options[:redirect_to]
      if redirect.blank? && session[:r]
        redirect = session[:r]
        redirect = user_url(user, redirect) if redirect && redirect.starts_with?('/')
        session[:r] = nil
      end
      redirect_to redirect || user_url(user)
    end
    
    def redirect_home_if_current_user
      redirect_to user_url(current_user) and return false if current_user
      true
    end
end
