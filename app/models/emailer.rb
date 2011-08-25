class Emailer < ActionMailer::Base
  helper :application, :comments, :url, :white_list

  def signup(current_service, user)
    setup     current_service,
                :subj => 'ммм... регистрация',
                :from => '"Ммм... тейсти" <noreply+signup@mmm-tasty.ru>',
                :user => user
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
  def love(current_service, transaction)
    setup     current_service,
                :subj => 'ммм... пожертвование',
                :from => '"Mmm... love" <noreply+love@mmm-tasty.ru>',
                :email => 'feedback@mmm-tasty.ru',
                :body => { :transaction => transaction, :user => transaction.user }
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
      @subject    = options[:subj].gsub("\r", '').gsub("\n", " ")
      @recipients = options[:email].blank? ? options[:user].email : options[:email]
      @from       = options[:from]

      @body[:current_service] = current_service
    end
end