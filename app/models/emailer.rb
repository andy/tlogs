class Emailer < ActionMailer::Base
  helper :application, :comments, :url, :white_list

  def signup(current_service, user)
    setup     current_service,
                :subj => 'ммм... регистрация',
                :from => '"Ммм... тейсти" <noreply+signup@mmm-tasty.ru>',
                :user => user
  end
  
  def link_notification(current_service, user, link)
    setup     current_service,
                :subj => 'ммм... ваш аккаунт привязан к другому',
                :from => '"Mmm... noreply <noreply@mmm-tasty.ru"',
                :reply_to => '"Mmm... premium" <premium@mmm-tasty.ru>',
                :body => { :user => user, :link => link }                
  end

  def confirm(current_service, user, email)
    setup     current_service,
                :subj => 'ммм... подтверждение емейл адреса',
                :from => '"Mmm... noreply" <noreply+signup@mmm-tasty.ru>',
                :email => email,
                :body => { :user => user, :email => email }
  end
  
  def message(current_service, user, message)
    setup     current_service,
                :subj => 'ммм.... новое личное сообщение',
                :from => '"Mmm... message" <noreply+messages@mmm-tasty.ru>',
                :user => user,
                :body => { :message => message }
  end
  
  def comment(current_service, user, comment)
    setup     current_service,
                :subj => "ммм... комментарий (#{comment.entry.excerpt})",
                :from => '"Mmm... comments" <noreply+comments@mmm-tasty.ru>',
                :user => user,
                :body => { :comment => comment }
  end  

  def comment_reply(current_service, user, comment)
    setup     current_service,
                :subj => "ммм... ответ на ваш комментарий (#{comment.entry.excerpt})",
                :from => '"Mmm... comments" <noreply+comments@mmm-tasty.ru>',
                :user => user,
                :body => { :comment => comment }
  end  
  
  # письмо для пользователей подписанных на комментарии
  def comment_to_subscriber(current_service, user, comment)
    setup     current_service,
                :subj => "ммм... комментарий (#{comment.entry.excerpt})",
                :from => '"Mmm... comments" <noreply+comments@mmm-tasty.ru>',
                :user => user,
                :body => { :comment => comment }
  end

  # письмо-напоминание о забытом пароле
  def lost_password(current_service, user)
    setup     current_service,
                :subj => 'ммм... напоминание пароля',
                :from => '"Mmm... password" <noreply+signup@mmm-tasty.ru>',
                :user => user
  end
  
  # письмо любовь от пользователя
  def invoice(current_service, invoice)
    setup     current_service,
                :subj     => 'ммм... премиум-подписка оплачена',
                :from     => '"Mmm... premium" <noreply+premium@mmm-tasty.ru>',
                :reply_to => '"Mmm... premium" <premium@mmm-tasty.ru>',
                :user     => invoice.user,
                :body     => { :invoice => invoice }
  end
  
  def premium_expires(current_service, user)
    setup     current_service,
                :subj     => 'ммм... до окончания премиум-подписки осталось 3 дня',
                :from     => '"Mmm... premium" <noreply+premium@mmm-tasty.ru>',
                :reply_to => '"Mmm... premium" <premium@mmm-tasty.ru>',
                :user     => user
  end
  
  def premium_expired(current_service, user)
    setup     current_service,
                :subj     => 'ммм... премиум-подаиска отключена',
                :from     => '"Mmm... premium" <noreply+premium@mmm-tasty.ru>',
                :reply_to => '"Mmm... premium" <premium@mmm-tasty.ru>',
                :user     => user
  end
  
  def destroy(current_service, user)
    setup     current_service,
                :subj => "ммм... удаление тлога #{user.url}",
                :from => '"Mmm... destroy" <noreply+destroy@mmm-tasty.ru>',
                :user => user
  end
  
  private
    def setup(current_service, options = {})
      # message specific things
      @body       = (options[:body] || {})
      @body[:user] = options[:user] if @body[:user].blank? && options[:user]
  
      # global settings
      @sent_on    = Time.now
      @headers    = {}
      @headers['Reply-To'] = options[:reply_to] if options[:reply_to]
      @subject    = options[:subj]
      @recipients = options[:email].blank? ? options[:user].email : options[:email]
      @from       = options[:from]

      @body[:current_service] = current_service
    end
end