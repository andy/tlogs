class MessagesController < ApplicationController
  before_filter :require_current_site, :require_confirmed_current_site, :require_confirmed_current_user

  before_filter :preload_message, :only => :destroy

  
  def create
    # set message options
    @message           = Message.new
    @message.body      = params[:message][:body]
    @message.user      = current_user
    @message.recipient = User.find_by_url(params[:message][:recipient_url])
    
    # set conversation options
    convo_options = params[:message].slice(:send_notifications)
    
    if @message.valid?
      # no way this can fail!
      @recipient_message = @message.begin_conversation!(convo_options)

      respond_to do |wants|
        wants.html { redirect_to user_url(current_site, conversation_path(@message.conversation)) }
        wants.js # render create.js
      end

      Emailer.deliver_message(current_service, @message.recipient, @recipient_message) if @recipient_message.should_be_delivered?
    else
      # bugs message
      respond_to do |wants|
        wants.html
        wants.js do
          render :update do |page|
            # re-enable submit button
            page << "jQuery('.submit_button input').removeAttr('disabled');"

            page.call :clear_all_errors
            page << "jQuery('#message_recipient_url').removeClass('input_error');"
            
            # check wether recipient is ok
            if @message.errors.on(:recipient)
              # remove the url
              page << "jQuery('#message_recipient').hide();"
              page << "jQuery('#message_recipient_url').addClass('input_error');"

              # update the status value
              if @message.recipient.nil? && params[:message][:recipient_url] 
                page << "jQuery('#subtext_message').attr('class', 'failure').html('указанный вами пользователь не найден');"
              else
                page << "jQuery('#subtext_message').attr('class', 'neutral').html('Укажите имя пользователя которому хотите написать сообщение');"
              end
            end

            # check wether message body is ok
            page.call :error_message_on, 'message_body', @message.errors.on(:body) if @message.errors.on(:body)
          end
        end
      end
    end
  end
  
  def destroy
    @message.destroy
  end
  

  protected
    def preload_message
      @message = Message.find(params[:id], :include => :conversation)

      @message.can_be_deleted_by?(current_user)
    end
end