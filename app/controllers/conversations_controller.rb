class ConversationsController < ApplicationController
  before_filter :require_current_user

  before_filter :require_confirmed_current_user

  before_filter :preload_conversation, :only => [:show, :subscribe, :unsubscribe, :mav, :destroy]
  
  before_filter :enable_shortcut

  protect_from_forgery

  layout 'main'

  helper :main


  def index
    @title = 'Все переписки'
    @empty = 'У вас нет переписок'
    @conversations = current_user.conversations.active.paginate(:page => current_page, :per_page => 15, :include => [:recipient, :last_message])
  end
  
  def unreplied
    @title = 'Неотвеченные'
    @empty = 'У вас нет неотвеченных переписок'
    @conversations = current_user.conversations.active.unreplied.paginate(:page => current_page, :per_page => 15, :include => :last_message)
    
    render :action => 'index'
  end
  
  def unviewed
    @title = 'Непросмотренные'
    @empty = 'У вас нет непросмотренных переписок'
    @conversations = current_user.conversations.active.unviewed.paginate(:page => current_page, :per_page => 15, :include => :last_message)
    
    render :action => 'index'
  end

  def search
    @messages = Message.search params[:query], :with => { :conversation_user_id => current_user.id }, :page => current_page, :per_page => 15, :order => 'created_at DESC'
  end
  
  
  def new
    @send_notifications = current_user.tlog_settings.email_messages && current_user.is_emailable?
    # @recipient = User.find_by_url(params[:url]) if params[:url]
    @message = Message.new :recipient_url => params[:url]
  end

  def show
    # mark as viewed automatically
    @conversation.toggle!(:is_viewed) unless @conversation.is_viewed?
    
    @messages = @conversation.messages.paginate(:page => current_page, :per_page => 15, :include => :user, :order => 'created_at DESC')
  end
  
  def subscribe
    @conversation.update_attribute(:send_notifications, true)
  end
  
  def unsubscribe
    @conversation.update_attribute(:send_notifications, false)
  end
  
  def mav
    @conversation.toggle!(:is_viewed) unless @conversation.is_viewed?
  end
  
  def verify_recipient
    @value        = params[:url]
    
    @recipient    = User.find_by_url(@value) if @value
    @conversation = current_user.conversations.active.find_by_recipient_id(@recipient) if @recipient    
  end
  
  def destroy    
    @conversation.async_destroy!
    
    respond_to do |wants|
      wants.html { redirect_to service_url(conversations_path) }
      wants.js # render destroy.rjs
    end
  end

  def mentions
    @mentions = current_user.public_friends+current_user.friends
    render :json => export_mentions(@mentions)
  end
  
  # Legacy
  def legacy_index
    redirect_to service_url(conversations_path)
  end
  
  def legacy_show
    redirect_to service_url(conversation_path(:id => params[:id]))
  end
  
  def legacy_new
    redirect_to service_url(new_conversation_path)
  end
  
  def legacy_named_new
    redirect_to service_url(named_new_conversation_path(:url => params[:url]))
  end
  
  protected
    def preload_conversation
      @recipient    = User.find_by_url params[:id]
      @conversation = current_user.conversations.active.find_by_recipient_id(@recipient.id)
      
      if @conversation.nil? && @recipient.nil?
        flash[:bad] = 'Запрошенная вами переписка не найдена'
        redirect_to service_url(conversations_path) and return false
      elsif @conversation.nil? && @recipient
        redirect_to service_url(named_new_conversation_path(:url => params[:id])) and return false
      else
        return true
      end
    end
end