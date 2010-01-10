class ConfirmController < ApplicationController
  before_filter :require_current_user, :only => [:required, :resend]
  before_filter :redirect_home_if_current_user_is_confirmed, :except => [:code]
  layout 'account'
  
  def required
  end
  
  def resend
    if request.post?
      current_user.update_confirmation!(current_user.email)
      Emailer.deliver_confirm(current_service, current_user, current_user.email)
      flash[:good] = "Загляните, пожалуйста, в почтовый ящик #{current_user.email}, там должно быть письмо с кодом подтверждения"
    end
    redirect_to service_url(confirm_path(:action => :required))
  end  

  # /confirm/code/13_4efeb9ce
  def code
    user = User.find(params[:code].split(/_/)[0].to_i) rescue nil
    render_tasty_404('Ошибка. Указанный код подтверждения не был найден') and return unless user
    
    render_tasty_404('Ошибка. Ваш аккаунт заблокирован') and return if user.is_disabled?

    email = user.validate_confirmation(params[:code])
    render_tasty_404('Ошибка. Указанный код подтверждения не работает') and return unless email

    user.email = (email || user.email)
    was_confirmed = user.is_confirmed?
    user.is_confirmed = true
    user.clear_confirmation
    if user.save
      # выставляем новую авторизационную куку, но только если он не по openid авторизуется
      cookies[:l] = {
          :value => user.email,
          :expires => 1.years.from_now,
          :domain => request.domain
        } unless user.is_openid?
    end
    flash[:good] = "Вы успешно подтвердили свой емейл, #{user.username}!"
    
    if current_user
      if was_confirmed
        redirect_to :action => 'email'
      else
        redirect_to user_url(current_user, settings_path)
      end
    else
      # перенаправляем пользователя в настройки его тлога
      session[:r] = user_url(current_user, settings_path) if !was_confirmed && current_user
      redirect_to service_url(login_path)
    end
  end
  
  private
    def redirect_home_if_current_user_is_confirmed
      redirect_to user_url(current_user, settings_path) and return false if current_user.is_confirmed?
      true
    end
end