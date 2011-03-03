class ConversationsController < ApplicationController
  before_filter :require_current_site, :require_confirmed_current_site, :require_confirmed_current_user

  before_filter :current_user_eq_current_site
  
  before_filter :preload_conversation, :only => [:show, :subscribe, :unsubscribe, :destroy]

  protect_from_forgery

  layout 'conversations'


  def index
    @title = 'Все переписки'
    @conversations = current_site.conversations.paginate(:page => params[:page], :per_page => 15, :include => [:recipient, :last_message])
  end
  
  def unreplied
    @title = 'Неотвеченные'
    @conversations = current_site.conversations.unreplied.paginate(:page => params[:page], :per_page => 15, :include => :last_message)
    
    render :action => 'index'
  end
  
  def new
    # @recipient = User.find_by_url(params[:url]) if params[:url]
    @message = Message.new :recipient_url => params[:url]
  end
  
  def search
    @messages = Message.search params[:query], :with => { :conversation_user_id => current_site.id }, :page => params[:page], :per_page => 15, :order => 'created_at DESC'
  end

  def show
    # mark as viewed automatically
    @conversation.toggle!(:is_viewed) unless @conversation.is_viewed?
    
    @messages = @conversation.messages.paginate(:page => params[:page], :per_page => 15, :include => :user, :order => 'created_at DESC')
  end
  
  def subscribe
    @conversation.update_attribute(:send_notifications, true)
  end
  
  def unsubscribe
    @conversation.update_attribute(:send_notifications, false)
  end
  
  def verify_recipient
    @value        = params[:url]
    
    @recipient    = User.find_by_url(@value) if @value
    @conversation = current_site.conversations.find_by_recipient_id(@recipient) if @recipient    
  end
  
  def destroy    
    @conversation.destroy
    
    respond_to do |wants|
      wants.html { redirect_to user_url(current_site, conversations_path) }
      wants.js # render destroy.rjs
    end
  end
  
  protected
    def preload_conversation
      @recipient    = User.find_by_url params[:id]
      @conversation = current_site.conversations.find_by_recipient_id(@recipient.id)
      
      if @conversation.nil? && @recipient.nil?
        return false
      elsif @conversation.nil? && @recipient
        redirect_to user_url(current_site, named_new_conversation_path(:url => params[:id])) and return false
      else
        return true
      end
    end
end