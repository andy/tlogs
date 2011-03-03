class TlogController < ApplicationController
  before_filter :require_current_site, :require_confirmed_current_user, :require_confirmed_current_site
  before_filter :find_entry, :only => [:show, :metadata, :subscribe, :unsubscribe, :destroy]
  before_filter :current_user_eq_current_site, :only => [:destroy, :private, :anonymous]

  before_filter :check_if_can_be_viewed, :only => [:index, :day]
  # protect_from_forgery :only => [:relationship, :tags, :metadata, :subscribe, :unsubscribe]

  helper :comments


  def index    
    # обновляем статистику для текущего пользователя
    if current_user && current_site.entries_count > 0 && !is_owner? && current_user.subscribed_to?(current_site)
      rel = current_user.reads(current_site)
      # обновляем количество просмотренных записей, если оно изменилось
      if current_site.entries_count_for(current_user) != rel.last_viewed_entries_count
        rel.last_viewed_at = Time.now
        rel.last_viewed_entries_count = current_site.entries_count_for(current_user)
        rel.save!
      end
    end

    if current_site.entries_count > 0 || is_owner?
      if current_site.tlog_settings.is_daylog?
        @time = current_site.last_public_entry_at
        day()
      else
        # переворачиваем страницы, они теперь будут показываться в обратном порядке
        total_pages = current_site.public_entries_count.to_pages
        @page = params[:page].to_i.reverse_page( total_pages ) rescue 1
        options = { :page => @page }
        if @page == 1 || is_owner? || !current_site.tlog_settings.past_disabled?
          @entries = current_site.recent_entries(options) # uses paginator, so entries are not really loaded
          @entries_array = @entries.to_a if @page > 1
        else
          @past_disabled = true
          @entries = []
        end
      end
    else
      render_tasty_404("Этот имя занято, но пользователь еще не сделал ни одной записи.<br/>Загляните, пожалуйста, позже.<br/><br/><a href='#{current_service.url}'>&#x2190; вернуться на главную</a>")
    end
  end
  
  def private
    redirect_to user_url(current_site) and return unless is_owner?
    
    @title = 'ваши скрытые записи'
    @entries = current_site.entries.private.for_view.paginate :page => params[:page], :per_page => Entry::PAGE_SIZE
  end
  
  def anonymous
    redirect_to user_url(current_site) and return unless is_owner?
    
    @title = 'ваши анонимки'
    @entries = current_site.entries.anonymous.for_view.paginate :page => params[:page], :per_page => Entry::PAGE_SIZE
    render :action => 'private'
  end

  # Вывести текущую запись
  def show
    # hide all non-public entries in the tlog    
    render :action => 'hidden' and return if !current_site.can_be_viewed_by?(current_user) && !@entry.is_mainpageable?
    
    if current_user && !is_owner?
      rel = current_user.reads(current_site)

      if current_site.entries_count_for(current_user) != rel.last_viewed_entries_count
        if rel.last_viewed_at.nil?
          rel.update_attributes!( :last_viewed_at => Time.now, :last_viewed_entries_count => current_user.entries_count_for(current_user))
        elsif @entry.created_at > rel.last_viewed_at && current_site.entries_count_for(current_user) > rel.last_viewed_entries_count
          Relationship.increment_counter(:last_viewed_entries_count, rel.id)
        end
      end
    end

    @comments = Rails.cache.fetch("comments_#{@entry.id}_#{@entry.comments_count}_#{@entry.updated_at.to_i}", :expires_in => 1.day) { @entry.comments.all(:include => { :user => :avatar }, :order => 'comments.id').reject { |comment| comment.user.nil? } }

    @last_comment_viewed = current_user ? CommentViews.view(@entry, current_user) : 0
    @comment = Comment.new_from_cookie(cookies['comment_identity']) if !current_user && !cookies['comment_identity'].blank?
    @comment ||= Comment.new
    @time = @entry.created_at
  end
  
  def metadata
    render :partial => 'metadata', :locals => { :entry => @entry }
  end
  
  def tags
    render :partial => 'tags'
  end

  def relationship
    redirect_to user_url(current_site) and return unless request.post?

    relationship = current_user.relationship_with(current_site, true)
    
    # internal error
    if relationship === false
      render :nothing => true
      
      return
    end

    # scucess
    if relationship && relationship.new_record?
      new_friendship_status = Relationship::DEFAULT
      
      # Emailer.deliver_relationship(current_site, current_user)
    else
      new_friendship_status = [Relationship::PUBLIC, Relationship::DEFAULT].include?(relationship.friendship_status) ? Relationship::GUESSED : Relationship::DEFAULT
    end
    current_user.set_friendship_status_for(current_site, new_friendship_status)
    
    render :update do |page|
      page.replace :sidebar_relationship, :partial => 'relationship'
      page.visual_effect :highlight, :sidebar_relationship, :duration => 0.3
    end
  end
  
  def subscribe
    render :nothing => true and return unless request.post?

    begin
      @entry.subscribers << current_user if current_user

      render :update do |page|
        page.toggle('subscribe_link', 'unsubscribe_link')
      end
    rescue ActiveRecord::StatementInvalid
      # ignore ... and just render nothing (this happens when user clicks too fast before getting previous update)
      render :nothing => true
    end

  end
  
  def unsubscribe
    render :nothing => true and return unless request.post?

    @entry.subscribers.delete(current_user) if current_user
    render :update do |page|
      page.toggle('subscribe_link', 'unsubscribe_link')
    end
  end

  def day
    begin
      @time ||= [params[:year], params[:month], params[:day]].join('-').to_date.to_time
    rescue
      # in case to_date returns an error (invalid date exception), get user back to main page
      redirect_to user_url(current_site) and return
    end

    @title = current_site.tlog_settings.title
    
    # если пользователь предпочел скрыть прошлое, делаем вид что такой страницы не существует
    if current_site.tlog_settings.past_disabled? && @time.to_date != current_site.last_public_entry_at.to_date && !is_owner?
      @past_disabled = true
      @entries = []
    else
      @entries = current_site.recent_entries(:time => @time)
    end
    render :action => 'day'
  end
  
  def next_day
    begin
      @time ||= [params[:year], params[:month], params[:day]].join('-').to_date.to_time
    rescue
      redirect_to user_url(current_site) and return
    end
    @entries = current_site.recent_entries(:time => @time)

  	d = @entries.first.next(:include_private => is_owner?).created_at rescue nil

    redirect_to d ? user_url(current_site, day_path(:year => d.year, :month => d.month, :day => d.mday)) : user_url(current_site)
  end
  
  def prev_day
    begin
      @time ||= [params[:year], params[:month], params[:day]].join('-').to_date.to_time
    rescue
      redirect_to user_url(current_site) and return
    end
    @entries = current_site.recent_entries(:time => @time)

  	d = @entries.last.prev(:include_private => is_owner?).created_at rescue nil

    redirect_to d ? user_url(current_site, day_path(:year => d.year, :month => d.month, :day => d.mday)) : user_url(current_site)
  end
  
  # удаляет запись из тлога
  def destroy
    url = tlog_url_for_entry(@entry)
    if @entry.is_anonymous?
      flash[:bad] = 'Извините, к сожалению, анонимки нельзя удалять'
    else
      @entry.destroy
      flash[:good] = 'Запись была удалена'
    end

    redirect_to url
  end  
  
  private
    def check_if_can_be_viewed
      render :action => 'hidden' and return false if not current_site.can_be_viewed_by?(current_user)
    end

    def find_entry
      @entry = Entry.find_by_id_and_user_id params[:id], current_site.id
      if @entry.nil? || (@entry.is_anonymous? && !is_owner?)
        respond_to do |format|
          format.html { render_tasty_404("Запрошенная вами запись не найдена.<br/><br/><a href='#{user_url(current_site)}'>&#x2190; вернуться в #{current_site.gender("его", "её")} тлог</a>") }
          format.js { render :text => "record with id #{params[:id].to_i} was not found in this tlog" }
        end
        return false
      elsif @entry.is_private? && !is_owner?
        respond_to do |format|
          format.html { render :text => "У Вас недостаточно прав для просмотра этой записи.<br/><br/><a href='#{user_url(current_site)}'>&#x2190; вернуться в #{current_site.gender("его", "её")} тлог</a>", :layout => '404', :status => 403 }
          format.js { render :text => 'this record is private and you have no access to it' }
        end
        return false
      end
      true
    end
end
