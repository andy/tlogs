class CommentsController < ApplicationController
  before_filter :require_current_site, :require_confirmed_current_user, :find_entry
  
  before_filter :check_if_can_be_viewed

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
  
  def destroy
    render :nothing => true and return unless (request.post? || request.delete?)

    render :json => false and return unless current_user

    @comment = Comment.find_by_id_and_entry_id(params[:id], @entry.id)
    
    render :json => false and return unless @comment

    @comment.destroy if @comment && @comment.is_owner?(current_user)
    
    render :json => { :restorable => false, :blacklistable => @comment.suggest_author_blacklisting_by?(current_user) }
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
      render(:text => 'sorry, you cant post comments here') and return false unless current_site.can_be_viewed_by?(current_user)
    end
end
