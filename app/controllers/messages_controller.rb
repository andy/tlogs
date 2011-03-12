class MessagesController < ApplicationController
  before_filter :require_current_site, :require_confirmed_current_site, :require_confirmed_current_user
  
  # can be viewed only by owner
  before_filter :current_user_eq_current_site

  before_filter :preload_message, :only => [:destroy]

  protect_from_forgery


  # this is an legacy redirect url
  def index
    redirect_to user_url(current_site, conversations_path)
  end
  
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

      @recipient_message.async_deliver!(current_service)

      respond_to do |wants|
        wants.html { redirect_to user_url(current_site, conversation_path(@message.conversation)) }
        wants.js # render create.js
      end

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