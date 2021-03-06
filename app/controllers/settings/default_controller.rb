class Settings::DefaultController < ApplicationController
  before_filter :require_current_user, :require_owner
  before_filter :require_confirmed_current_user

  protect_from_forgery

  helper :settings
  layout "settings"

  def index
    @tlog_settings = current_user.tlog_settings

    if request.post?
      @tlog_settings.is_daylog = params[:tlog_settings][:is_daylog]
      @tlog_settings.default_visibility = params[:tlog_settings][:default_visibility]
      @tlog_settings.comments_enabled = params[:tlog_settings][:comments_enabled]
      @tlog_settings.past_disabled = params[:tlog_settings][:past_disabled]
      @tlog_settings.privacy = params[:tlog_settings][:privacy]

      if @tlog_settings.save
        flash[:good] = 'Настройки сохранены'
        redirect_to user_url(current_user, settings_path)
      else
        flash[:bad] = 'Произошла какая-то ошибка и ваши настройки не удалось сохранить'
      end
    end
  end

  def invitations
    if request.post? && params[:invitation] && params[:invitation][:email]

      if current_user.invitations_left.nonzero?
        User.transaction do
          @invitation = current_user.invitations.build :email => params[:invitation][:email], :code => SecureRandom.hex(10)
          if @invitation.valid?
            @invitation.save && current_user.decrement!(:invitations_left)

            Emailer.deliver_invitation(current_service, current_user, @invitation)
            flash[:good] = 'Прекрасно, мы отправили приглашение. Кажется, нас станет еще больше.'

            redirect_to settings_path(:action => :invitations)
          else
            flash[:bad] = 'Что-то пошло не так'
          end
        end
      else
        flash[:bad] = 'К сожалению, у вас закончились приглашения'

        redirect_to settings_path(:action => :invitations)
      end
    end

    @invitation ||= current_user.invitations.build
    @invitations = current_user.invitations.reload
  end

  def revoke_invitation
    success = false

    User.transaction do
      @invitation = current_user.invitations.find_by_id(params[:id])

      if @invitation && @invitation.invitee_id.nil?
        @invitation.destroy

        success = true

        current_user.increment!(:invitations_left)
      end
    end

    if success
      render :update do |page|
        page.visual_effect :highlight, dom_id(@invitation), :duration => 0.5
        page.visual_effect :fade, dom_id(@invitation), :duration => 0.5

        page.show 'invitations_send_form'
        page.hide 'invitations_required'

        page.delay(0.6) do
          page.remove dom_id(@invitation)

          page << "
            if(jQuery('.invitation').length == 0) {
              jQuery('#invitations_revokable_form').hide();
            }
          "
        end
      end
    else
      render :json => false
    end
  end

  # общие настройки пользователя
  def user_common
    @user = current_user
    @tlog_settings = current_user.tlog_settings

    if request.post?
      # достаем настройки. здесь это будут username и gender
      @user.gender = %w(m f).include?(params[:user][:gender]) ? params[:user][:gender] : 'f'
      @user.username = params[:user][:username]
      @user.save

      if params[:tlog_settings]
        @tlog_settings.about = params[:tlog_settings][:about]
        @tlog_settings.title = params[:tlog_settings][:title]
        @tlog_settings.save
      end

      if params[:user][:userpic]
        @user.userpic = params[:user][:userpic]
        # destroy legacy avatar if any
        # current_user.avatar.destroy if current_user.avatar

        @user.valid?
        if !@user.errors.on(:userpic)
          @user.save!
        else
          flash[:bad] = 'Не удалось изменить ваш портрет — убедитесь, что картинка, которую вы загружаете, имеет расширение .jpg, .png или .gif (если расширение правильное, то, скорее всего, картинка слишком большая — уменьшите её и попробуйте снова)'

          render and return
        end
      end

      if @user.errors.empty? && @tlog_settings.errors.empty?
        flash[:good] = 'Великолепно! Ваши настройки сохранены'
        expire_fragment(:controller => '/tlog', :action => 'index', :content_for => 'layout')
      else
        flash[:bad] = 'Не удалось сохранить настройки из-за каких-то ошибок'
      end
    end
  end

  def deuserpic
    render :nothing => true and return unless request.delete?

    # destroy legacy avatar
    # current_user.avatar.destroy if current_user.avatar

    # clear userpic paperclip way
    if current_user.userpic?
      current_user.userpic = nil
      current_user.save!
    end

    flash[:good] = 'Ваш аватар был удален'
    redirect_to :action => :user_common
  end

  def force_signature_change
    redirect_to :action => 'password' and return unless request.post?

    flash[:good] = 'Все сессии разлогинены'
    current_user.update_attribute :created_at, current_user.created_at.since(1.second)
    update_cookie_sig!(current_user)

    current_user.log nil, :session, 'все сессии разлогинены', nil, request.remote_ip

    redirect_to :action => 'password'
  end

  def password
    redirect_to :action => 'index' and return if current_user.crypted_password.blank?
    if request.post?
      if User.encrypt(params[:user_old_password], current_user.salt) == current_user.crypted_password && params[:user_new_password] == params[:user_new_password_repeat]
        current_user.password = params[:user_new_password]
        if current_user.save
          update_cookie_sig!(current_user)
          flash[:good] = 'Отлично! Вы успешно изменили свой пароль'
          redirect_to :action => 'password'
        else
          flash[:bad] = 'Не удалось изменить пароль потому что вы либо неправильно указали старый пароль, либо два новых пароля не совпадают'
         end
      else
        flash[:bad] = 'Не удалось изменить пароль потому что вы либо неправильно указали старый пароль, либо два новых пароля не совпадают'
      end
    end

    @changelogs = current_user.changelogs.auth.paginate :page => 1, :per_page => 20, :order => 'id desc'
  end

  def agreement
  end

  def rss
    @settings = current_user.settings
    @tlog_settings = current_user.tlog_settings
  end

  def design
    @design = current_site.tlog_design_settings || current_site.create_tlog_design_settings

    { "color_tlog_text"     => "414141",
      "color_sidebar_text"  => "FFFFFF",
      "color_voter_bg"      => "BCBCBC",
      "color_highlight"     => "FF5300",
      "color_tlog_bg"       => "FFFFFF",
      "color_voter_text"    => "FFFFFF",
      "color_link"          => "FF5300",
      "color_sidebar_bg"    => "000000",
      "color_date"          => "858585"
    }.each do |key, value|
      @design.send("#{key}=", value) if @design.send(key).blank?
    end

    if request.post?
      TlogDesignSettings.transaction do
        @design ||= TlogDesignSettings.new
        @design.update_attributes!(params[:design])
        @design.user = current_site

        TlogSettings.increment_counter(:css_revision, current_site.tlog_settings.id)

        if params[:attachment] && !params[:attachment][:uploaded_data].blank?
          @tlog_background = TlogBackground.new params[:attachment]
          @design.tlog_background.destroy if @design.tlog_background
          @tlog_background.tlog_design_settings = @design

          if @tlog_background.valid?
            @tlog_background.save!

            # обновляем адрес..
            @design.update_attributes!({ :background_url => @tlog_background.public_filename })
          else
            flash[:bad] = 'К сожалению не получилось изменить фоновую картинку — проверьте что файл, который вы заливаете, имеет расширение .jpg, .png или .gif (а если картинка в каком-то из этих форматов, то скорее всего она просто очень большая)'
            return
          end
        end

        flash[:good] = 'Настройки сохранены'
        redirect_to user_url(current_site, settings_path(:action => :design))
      end
    end
  end

  def email
    @user = User.find(current_user.id)
    @tlog_settings = current_user.tlog_settings

    @email = @user.read_confirmation_email

    if request.post?
      @user.email_comments = params[:user][:email_comments]
      @user.comments_auto_subscribe = params[:user][:comments_auto_subscribe]
      @user.save

      @email = params[:user][:email]

      @tlog_settings.update_attributes({
        :tasty_newsletter => params[:tlog_settings][:tasty_newsletter],
        :email_messages   => params[:tlog_settings][:email_messages]
      })

      flash[:good] = 'Здорово! Мы успешно сохранили ваши почтовые настройки'

      # меняем емейл адрес. для того чтобы случайно не проапдейтить пользователя, мы создаем копию и проверяем
      #  валидность емейла уже на ней
      new_email = params[:user][:email] ? params[:user][:email].strip : ''
      password  = params[:user][:password] ? params[:user][:password] : ''

      if !new_email.blank? && current_user.email != new_email
        if @user.valid_password?(password)
          if User.find_by_email(new_email)
            flash[:bad] = 'К сожалению, пользователь с таким емейлом уже существует'
            @user.errors.add(:email, 'к сожалению, этот емейл занят')
          else
            # CHANGE TO NEW EMAIL
            @user.email = new_email
            @user.is_confirmed = false
            @user.valid?
            if !@user.errors.on :email
              @user.log nil, :change_email, "сменил емейл адрес на #{new_email}", nil, request.remote_ip
              current_user.update_confirmation!(@user.email)
              update_cookie_sig!(@user)
              Emailer.deliver_confirm(current_service, current_user, @user.email)
              flash[:good] = "Отлично! Мы установили Вам новый емейл адрес, но прежде чем он заработает, вам нужно будет его подтвердить. Поэтому загляните, пожалуйста, в почтовый ящик #{@user.email}, там должно быть письмо с кодом подтверждения"
              redirect_to user_url(current_site, settings_path(:action => 'email'))
              return
            else
              flash[:bad] = "Ошибка! Не получилось сохранить настройки, потому что #{@user.errors.on :email}"
            end
          end
        else
          @user.errors.add(:password, 'указан неправильный пароль')
          flash[:bad] = 'Вы ввели неправильный пароль'
        end
      end
    end
  end

  # Удаление тлога
  def destroy
    @user = User.active.find(current_user.id)

    if request.post?
      if params[:agree] == '1'
        Emailer.deliver_destroy(current_service, @user)

        flash[:good] = 'Вам на почту было отправлено сообщение с кодом для удаления тлога'
      else
        flash[:bad] = 'Нужно согласиться с удалением тлога'
      end
    end
  end

  def destroy_confirm
    @user = User.active.find(current_user.id)
    @code = params[:code]

    if @code != current_user.destroy_code
      flash[:bad] = 'Неверный авторизационный код, тлог не может быть удален'

      redirect_to user_url(current_user, settings_path(:action => 'destroy'))
    elsif request.post?
      flash[:good] = 'Тлог был успешно удален'

      @user.log nil, :disable, "удалил аккаунт", nil, request.remote_ip
      @user.async_disable!

      # выходим с сайта
      cookies.delete :t, :domain => current_service.cookie_domain
      cookies.delete :l, :domain => current_service.cookie_domain
      cookies.delete :s, :domain => current_service.cookie_domain
      reset_session

      redirect_to service_url
    end
  end
end
