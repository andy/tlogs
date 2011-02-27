class MessagesController < ApplicationController
  before_filter :require_current_site, :require_confirmed_current_site, :require_confirmed_current_user

  before_filter :preload_message, :only => [:destroy]

  
  def create
    @disable_ajax_refresh = params[:disable_ajax_refresh] || false
    @disable_flash        = params[:disable_flash] || false
    @last_message_id      = params[:last_message_id].to_i rescue false
    
    # set message options
    @message           = Message.new
    @message.body      = params[:message][:body]
    @message.user      = current_user
    @message.recipient = User.find_by_url(params[:message][:recipient_url])
    
    # set conversation options, but only take them if they exist
    convo_options = params[:message].slice(:send_notifications).symbolize_keys

    
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
        wants.html { } # FIX ME? what to do here?
        wants.js
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