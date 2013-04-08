class AnonymousController < ApplicationController
  before_filter :require_current_user, :only => [:subscribe, :unsubscribe, :comment, :comment_destroy, :comment_action]

  before_filter :require_confirmed_current_user, :only => [:subscribe, :unsubscribe, :comment_destroy, :comment, :comment_action]
  
  before_filter :preload_entry, :only => [:show, :preview, :toggle, :comment, :subscribe, :unsubscribe, :mentions]

  before_filter :require_commentable_entry, :only => [:comment, :subscribe, :unsubscribe, :mentions]

  before_filter :require_post_request, :only => [:preview, :comment, :toggle, :subscribe, :unsubscribe, :ban_ac]

  before_filter :require_not_ac_banned, :only => [:preview, :comment, :comment_destroy, :mentions, :comment_action]

  before_filter :require_moderator, :only => [:toggle, :ban_ac]
  
  before_filter :enable_shortcut, :only => [:index, :show]

  layout 'main'
  helper :main, :comments


  # смотрим список записей
  def index
    sql_conditions = 'type="AnonymousEntry" AND is_disabled = 0'

    @entry_ids = Entry.paginate :all, :select => 'entries.id', :conditions => sql_conditions, :page => current_page, :per_page => Entry::PAGE_SIZE, :order => 'entries.id DESC'

    @entries = Entry.find_all_by_id @entry_ids.map(&:id), :include => :author, :order => 'entries.id DESC'
    
    @comment_views = User::entries_with_views_for(@entries.map(&:id), current_user)
  end
  

  # скрывает или показывает запись
  def toggle
    if @entry.is_disabled?
      @entry.toggle!(:is_disabled)
      @entry.author.log current_user, :ac_show, "восстановил анонимку", @entry, request.remote_ip
    else
      @entry.toggle!(:is_disabled)
      @entry.author.log current_user, :ac_hide, "удалил анонимку", @entry, request.remote_ip
    end
  end
  
  
  # смотрим запись
  def show    
    @comments = @entry.comments.enabled.all(:include => :user, :order => 'comments.id').reject { |c| c.user.nil? } if @entry.comments_count > 0

    @comment = Comment.new
    
    @last_comment_viewed = current_user ? CommentViews.view(@entry, current_user) : 0    
  end
  
  def mentions
    user_ids    = Comment.find(:all, :select => "user_id", :conditions => "entry_id = #{@entry.id}").map(&:user_id).reject { |id| id == current_user.id || id == @entry.user_id }.uniq
    @mentions   = User.find(user_ids) if user_ids.any?
    @mentions ||= []
    
    render :template => 'mentions/index', :content_type => Mime::JSON.to_s
  end
  
  # удаляем комментарий
  def comment_destroy
    render :nothing => true and return unless request.delete?

    render :json => false and return unless current_user

    @comment = Comment.find_by_id(params[:id])
    
    render :json => false and return unless @comment
    
    render :json => false and return if @comment.is_disabled?

    @comment.disable! if @comment.is_owner?(current_user)
    
    reportable = @comment.can_be_reported_by?(current_user) && !@comment.was_reported_by?(current_user)
    
    render :json => { :reportable => reportable }
  end
  
  
  # добавляем комментарий
  def comment
    @comment          = Comment.new(params[:comment])
    @comment.user     = current_user
    @comment.request  = request
    @comment.entry_id = @entry.id

    @comment.valid?
    
    if @comment.errors.empty?
      @comment.save!
      
      @comment.async_deliver!(current_service, params[:reply_to])
      
      # автоматически подписываем пользователя если на комментарии к этой записи если он еще не подписан
      @entry.subscribers << current_user if current_user && current_user.comments_auto_subscribe? && @entry.user_id != current_user.id && !@entry.subscribers.map(&:id).include?(current_user.id)      
    end

    respond_to do |wants|
      wants.html { redirect_to service_url(anonymous_path(:action => :show, :id => @entry.id)) }
      wants.js # comment.rjs
    end
  end
  
  def comment_action
    render :nothing => true and return unless request.post?
    
    render :json => false, :status => 403 and return unless current_user
  
    @comment = Comment.find params[:id]
        
    render :json => false, :status => 404 and return unless @comment
    
    render :json => false, :status => 404 and return unless @comment.entry.is_anonymous?
    
    render :json => false, :status => 403 and return unless @comment.can_be_reported_by?(current_user)
    
    @comment.report!(current_user) unless @comment.was_reported_by?(current_user)
    
    render :json => true    
  end
  
  # предпросматриваем комментарий
  def preview
    @comment            = Comment.new(params[:comment])
    @comment.user       = current_user
    @comment.request    = request

    @comment.valid?
  end

  
  # subscribe to entry comments
  def subscribe
    @entry.subscribers << current_user

  rescue ActiveRecord::StatementInvalid
    # ignore ... and just render nothing (this happens when user clicks too fast before getting previous update)
    render :nothing => true
  end


  # unsubscribe from entry comments
  def unsubscribe
    @entry.subscribers.delete(current_user)
  end
  
  def ban_ac
    @comment = Comment.find_by_id(params[:id])

    @comment.user.ban_ac!(@comment.entry, @comment, params[:duration])
    
    @comment.user.log current_user, :ac_ban, "забанен на #{params[:duration]}", @comment, request.remote_ip
    
    render :update do |page|
      page.replace(dom_id(@comment, :ban), :partial => 'globals/ban_controls', :locals => { :comment => @comment })
      page.visual_effect :highlight, dom_id(@comment, :ban)
    end
  end
  
  protected
    def preload_entry
      @entry = Entry.find_by_id_and_type params[:id], 'AnonymousEntry'

      # если запись не была найдена
      unless @entry
        request.get? ? redirect_to(:action => 'index') : render(:text => 'oops, entry not found', :status => 404)

        return false
      end

      # если анонимка была удалена
      if @entry.is_disabled?

        if request.get?
          flash[:bad] = 'Запрашиваемая вами анонимка была удалена'
          redirect_to :action => 'index'          
        else
          render :text => 'Запрашиваемая вами анонимка была удалена', :status => 404
        end
        
        return false
      end

      # все окей ...
      return true
    end
    
    def require_not_ac_banned
      render :nothing => true and return false if current_user.is_ac_banned?
    end
    
    def require_post_request
      render :nothing => true and return false unless request.post?
    end
    
    def require_commentable_entry
      render(:text => 'comments disabled for this entry, sorry') and return false unless @entry.comments_enabled?
    end
end