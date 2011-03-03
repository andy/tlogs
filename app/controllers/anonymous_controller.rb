class AnonymousController < ApplicationController
  before_filter :require_current_user, :only => [:subscribe, :unsubscribe, :comment, :comment_destroy]
  before_filter :require_confirmed_current_user, :only => [:subscribe, :unsubscribe, :comment_destroy, :comment]
  
  before_filter :preload_entry, :only => [:show, :preview, :toggle, :comment, :subscribe, :unsubscribe]
  before_filter :require_commentable_entry, :only => [:comment, :subscribe, :unsubscribe]

  before_filter :require_post_request, :only => [:preview, :comment, :toggle, :subscribe, :unsubscribe]

  before_filter :require_moderator, :only => [:toggle]

  layout 'main'
  helper :main, :comments


  # смотрим список записей
  def index
    sql_conditions = 'type="AnonymousEntry" AND is_disabled = 0'
    
    # кешируем общее число записей, потому что иначе :page обертка будет вызывать счетчик на каждый показ
    total = Rails.cache.fetch('entry_count_anonymous', :expires_in => 10.minutes) { Entry.count :conditions => sql_conditions }

    @page = params[:page].to_i.reverse_page(total.to_pages)
    
    @entry_ids = Entry.find :all, :select => 'entries.id', :conditions => sql_conditions, :page => { :current => @page, :size => Entry::PAGE_SIZE, :count => total }, :order => 'entries.id DESC'
    @entries = Entry.find_all_by_id @entry_ids.map(&:id), :order => 'entries.id DESC'
    
    @comment_views = User::entries_with_views_for(@entries.map(&:id), current_user)
  end
  

  # скрывает или показывает запись
  def toggle
    @entry.toggle!(:is_disabled)

    Rails.cache.delete('entry_count_anonymous')
  end
  
  
  # смотрим запись
  def show
    @comment = Comment.new
    
    @last_comment_viewed = current_user ? CommentViews.view(@entry, current_user) : 0    
  end
  
  
  # удаляем комментарий
  def comment_destroy
    render :nothing => true and return unless request.delete?

    @comment = Comment.find_by_id(params[:id])
    
    if @comment
      @comment.destroy if current_user && @comment.is_owner?(current_user)
    
      respond_to do |wants|
        wants.html { flash[:good] = 'Комментарий был удален'; redirect_to service_url(anonymous_path(:action => 'show', :id => @comment.entry_id)) }
        wants.js # comment_destroy.rjs
      end
    else
      respond_to do |wants|
        wants.html { flash[:bad] = 'Комментарий не найден'; redirect_to :back }
        wants.js { render :update do |page|
          page.call 'window.location.reload'
        end }
      end
    end
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

      users = []
      if !params[:reply_to].blank?
        comment_ids = params[:reply_to].split(',').map(&:to_i)
        # выбирает все комментарии для этой записи и достаем оттуда уникальных пользователей
        reply_to = Comment.find(comment_ids, :conditions => "entry_id = #{@entry.id}").map(&:user_id).reject { |id| id <= 0 }.uniq
        users = User.find(reply_to).reject { |user| !user.email_comments? }
      end

      # отправляем комментарий владельцу записи
      if @entry.author.is_emailable? && @entry.author.email_comments? && (!current_user || @entry.user_id != current_user.id)
        Emailer.deliver_comment(current_service, @entry.author, @comment)
      end
      
      # отправляем комменатрий каждому пользователю
      users.each do |user|
        Emailer.deliver_comment_reply(current_service, user, @comment) if user.is_emailable? && user.email_comments? && user.id != @entry.author.id
      end
      
      # отправляем сообщение всем тем, кто наблюдает за этой записью, и кому мы еще ничего не отправляли
      (@entry.subscribers - users).each do |user|
        Emailer.deliver_comment_to_subscriber(current_service, user, @comment) if user.is_emailable? && user.email_comments? && user.id != current_user.id
      end
      
      # автоматически подписываем пользователя если на комментарии к этой записи если он еще не подписан
      @entry.subscribers << current_user if current_user && current_user.comments_auto_subscribe? && @entry.user_id != current_user.id && !@entry.subscribers.map(&:id).include?(current_user.id)      
    end

    respond_to do |wants|
      wants.html { redirect_to service_url(anonymous_path(:action => :show, :id => @entry.id)) }
      wants.js # comment.rjs
    end
  end
  
  
  # предпросматриваем комментарий
  def preview
    @comment            = Comment.new(params[:comment])
    @comment.user       = current_user
    @comment.remote_ip  = request.remote_ip

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
          flash[:bad] = 'Запрошиваемая вами анонимка была удалена'
          redirect_to :action => 'index'          
        else
          render :text => 'Запрашиваемая вами анонимка была удалена', :status => 404
        end
        
        return false
      end
      
      # все окей ...
    end
    
    def require_post_request
      render :nothing => true and return false unless request.post?
    end
    
    def require_commentable_entry
      render(:text => 'comments disabled for this entry, sorry') and return false unless @entry.comments_enabled?
    end
end