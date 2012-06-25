class CommentsController < ApplicationController
  before_filter :require_current_site, :require_confirmed_current_user, :find_entry
  
  before_filter :check_if_entry_can_be_viewed
  
  before_filter :check_if_can_be_commented


  def preview
    render :nothing => true and return unless request.post?

    @comment = Comment.new(params[:comment])
    @comment.user = current_user if current_user
    @comment.remote_ip = request.remote_ip
    @comment.valid?

    render :update do |page|
      page.call :clear_all_errors
      # если есть ошибки...
      if @comment.errors.size > 0
        @comment.errors.each do |element, message|
          page.call :error_message_on, "comment_#{element}", message
        end
      else
        # иначе рендерим темлплейт
        page.replace_html 'comment_preview', :partial => 'preview'
      end
    end
  end

  # POST /entry/:entry_id/comments
  def create
    render :nothing => true and return unless request.post?
    
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
      
      respond_to do |wants|
        wants.html { redirect_to user_url(@entry.author, entry_path(@entry)) }
        wants.js { render :update do |page|
          page.call :clear_all_errors
          page.call 'window.location.reload'
        end }
      end
    else
      render :update do |page|
        page.call :clear_all_errors
        @comment.errors.each do |element, message|
          page.call :error_message_on, "comment_#{element}", message
        end
      end
    end
  end
  
  def erase
    render :nothing => true and return unless request.post?
    
    render :json => false, :status => 403 and return unless current_user
    
    @comment = Comment.find_by_id_and_entry_id(params[:id], @entry.id)

    render :json => false, :status => 404 and return unless @comment
    
    render :json => false, :status => 404 and return unless @comment.is_disabled?

    # only tlog owner can do this
    render :json => false, :status => 403 and return unless @entry.user_id == current_user.id
    
    @entry.async_erase_comments_by(@comment.user)
    
    render :json => true
  end
  
  def blacklist
    render :nothing => true and return unless request.post?
    
    render :json => false, :status => 403 and return unless current_user
    
    @comment = Comment.find_by_id_and_entry_id(params[:id], @entry.id)

    render :json => false, :status => 404 and return unless @comment
    
    render :json => false, :status => 404 and return unless @comment.is_disabled?
    
    # only tlog owner can do this
    render :json => false, :status => 403 and return unless @entry.user_id == current_user.id

    current_user.set_friendship_status_for @comment.user, Relationship::BLACKLISTED
    
    suggestErase = !@entry.comments.enabled.find_all_by_user_id(@comment.user_id).count.zero?
    
    render :json => { :suggestErase => suggestErase }
  end
  
  def restore
    render :nothing => true and return unless request.post?
    
    render :json => false, :status => 403 and return unless current_user
    
    @comment = Comment.find_by_id_and_entry_id(params[:id], @entry.id)

    render :json => false, :status => 404 and return unless @comment
    
    render :json => false, :status => 404 and return unless @comment.is_disabled?
    
    render :json => false, :status => 403 and return unless @comment.can_be_restored_by?(current_user)

    @comment.restore!
    
    render :json => true
  end
  
  def report
    render :nothing => true and return unless request.post?
    
    render :json => false, :status => 403 and return unless current_user
  
    @comment = Comment.find_by_id_and_entry_id(params[:id], @entry.id)
    
    render :json => false, :status => 404 and return unless @comment
    
    render :json => false, :status => 403 and return unless @comment.can_be_reported_by?(current_user)
    
    @comment.report!(current_user) unless @comment.was_reported_by?(current_user)
    
    render :json => true
  end
  
  def destroy
    render :nothing => true and return unless (request.post? || request.delete?)

    render :json => false and return unless current_user

    @comment = Comment.find_by_id_and_entry_id(params[:id], @entry.id)
    
    render :json => false and return unless @comment
    
    render :json => false and return if @comment.is_disabled?

    @comment.disable! if @comment.is_owner?(current_user)
    
    restorable    = @comment.can_be_restored_by?(current_user)
    reportable    = @comment.can_be_reported_by?(current_user) && !@comment.was_reported_by?(current_user)
    blacklistable = @comment.can_be_blacklisted_by?(current_user)
    
    render :json => { :restorable => restorable, :reportable => reportable, :blacklistable => blacklistable, :is_premium => current_user.is_premium? }
  end
  
  private
    # проверка доступа к комментированию записи.
    def find_entry
      @entry = Entry.find_by_id_and_user_id(params[:entry_id], current_site.id)
      render(:text => "bad entry id, sorry") and return false \
              unless @entry

      if params[:action] != 'destroy'
        render(:text => "comments disabled for this entry, sorry, #{params[:action]}") and return false \
              unless @entry.comments_enabled?
      end

      render(:text => 'sorry, anonymous users are not allowed to comment') and return false \
              unless current_user

      render(:text => 'sorry, you need to confirm your email address first') and return false \
              unless current_user.is_confirmed?

      true
    end
    
    def check_if_can_be_viewed
      render(:text => 'sorry, you cant post comments here', :status => 403) and return false unless current_site.can_be_viewed_by?(current_user)
    end
    
    def check_if_entry_can_be_viewed
      render(:text => 'sorry, you cant post comments here', :status => 403) and return false unless @entry.can_be_viewed_by?(current_user)
    end
    
    def check_if_can_be_commented
      render(:text => 'sorry, you cant comment on this entry', :status => 403) and return false unless @entry.can_be_commented_by?(current_user)
    end
end
