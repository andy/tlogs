class Emailer < ActionMailer::Base
  helper :application, :comments, :url

  def signup(current_service, user)
    setup     current_service,
                :subj => 'ммм... регистрация',
                :from => '"Ммм... тейсти" <noreply@mmm-tasty.ru>',
                :user => user
  end

  def confirm(current_service, user, email)
    setup     current_service,
                :subj => 'ммм... подтверждение емейл адреса',
                :from => '"Mmm... noreply" <noreply@mmm-tasty.ru>',
                :email => email,
                :body => { :user => user, :email => email }
  end
  
  def message(current_service, user, message)
    setup     current_service,
                :subj => 'ммм.... новое личное сообщение',
                :from => '"Mmm... message" <messages@mmm-tasty.ru>',
                :user => user,
                :body => { :message => message }
  end
  
  def comment(current_service, user, comment)
    setup     current_service,
                :subj => "ммм... комментарий (#{comment.entry.excerpt})",
                :from => '"Mmm... comments" <comments@mmm-tasty.ru>',
                :user => user,
                :body => { :comment => comment }
  end  

  def comment_reply(current_service, user, comment)
    setup     current_service,
                :subj => "ммм... ответ на Ваш комментарий (#{comment.entry.excerpt})",
                :from => '"Mmm... comments" <comments@mmm-tasty.ru>',
                :user => user,
                :body => { :comment => comment }
  end  
  
  # письмо для пользователей подписанных на комментарии
  def comment_to_subscriber(current_service, user, comment)
    setup     current_service,
                :subj => "ммм... комментарий (#{comment.entry.excerpt})",
                :from => '"Mmm... comments" <comments@mmm-tasty.ru>',
                :user => user,
                :body => { :comment => comment }
  end

  # письмо-напоминание о забытом пароле
  def lost_password(current_service, user)
    setup     current_service,
                :subj => 'ммм... напоминание пароля',
                :from => '"Mmm... password" <noreply@mmm-tasty.ru>',
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
      @subject    = options[:subj]
      @recipients = options[:email].blank? ? options[:user].email : options[:email]
      @from       = options[:from]

      @body[:current_service] = current_service
    end
end