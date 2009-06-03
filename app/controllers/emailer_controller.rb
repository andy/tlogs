class EmailerController < ApplicationController
  before_filter :preload_mail


  def index
    render :layout => 'white'
  end
  
  def part
    @part = @mail.parts.select { |part| part.content_type == 'text/html' }.first
    
    render :layout => nil
  end
  
  private
    def preload_mail
      @method_name = params[:method_name]

      user = User.first

      case @method_name
      when 'comment'
        @mail = Emailer.create_comment(user, Comment.find_by_user_id(user.id))
      when 'comment_reply'
        @mail = Emailer.create_comment_reply(user, Comment.find_by_user_id(2))
      when 'comment_to_subscriber'
        @mail = Emailer.create_comment_to_subscriber(user, Comment.last)
      when 'confirm'
        @mail = Emailer.create_confirm(user, user.email)
      when 'lost_password'
        @mail = Emailer.create_lost_passwrod(user)
      when 'message'
        @mail = Emailer.create_message(user, user.messages.first)
      when 'signup'
        @mail = Emailer.create_signup(user)
      end
      
      true 
    end
end