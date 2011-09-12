class TlogController < ApplicationController
  before_filter :require_current_site, :require_confirmed_current_user, :require_confirmed_current_site
  before_filter :find_entry, :only => [:show, :metadata, :subscribe, :unsubscribe, :destroy]
  before_filter :require_owner, :only => [:destroy, :private, :anonymous]

  # 1 - protect global tlog index
  before_filter :check_if_can_be_viewed, :only => [:index, :daylog]
  
  # 1.1 - check wether url is right
  before_filter :set_time, :only => [:daylog, :next_day, :prev_day]

  # 2 - check wether that is empty or not
  before_filter :taken_but_empty, :only => [:index, :daylog, :show]

  # 3 - protect each entry individually
  before_filter :check_if_entry_can_be_viewed, :only => [:show]

  # 4 - we know it is visible - so mark as viewed
  before_filter :mark_as_viewed, :only => [:index, :daylog, :show]

  # protect_from_forgery :only => [:relationship, :tags, :metadata, :subscribe, :unsubscribe]

  caches_action :style

  helper :comments


  def index
    current_site.tlog_settings.is_daylog? ? daylog(current_site.last_public_entry_at) : regular
  end
  
  # When enabled as regular tlog
  def regular
    # переворачиваем страницы, они теперь будут показываться в обратном порядке
    total_pages = current_site.public_entries_count.to_pages
    @page = params[:page].to_i rescue 1
    @page = 1 if @page <= 0
    options = { :page => @page }
    if @page == 1 || is_owner? || !current_site.tlog_settings.past_disabled?
      @entries = current_site.recent_entries(options) # uses paginator, so entries are not really loaded
      @entries_array = @entries.to_a if @page > 1
    else
      @past_disabled = true
      @entries = []
    end
    
    @iscroll        = true if @page == 1 || is_owner? || !current_site.tlog_settings.past_disabled?
    @iscroll_active = true if params[:_is]
    
    render :action => 'regular'
  end
  
  # When enabled as daylog
  def daylog(time = nil)
    @time ||= time
    
    redirect_to user_url(current_site) and return if @time.nil?

    # если пользователь предпочел скрыть прошлое, делаем вид что такой страницы не существует
    if current_site.tlog_settings.past_disabled? && @time.to_date != current_site.last_public_entry_at.to_date && !is_owner?
      @past_disabled = true
      @entries = []
    else
      @entries = current_site.recent_entries(:time => @time, :per_page => 50)
    end

    render :action => 'daylog'
  end
  
  # Private entries
  def private
    @title = 'ваши скрытые записи'
    @entries = current_site.entries.private.for_view.paginate :page => params[:page], :per_page => Entry::PAGE_SIZE
  end
  
  # Anonymous entries
  def anonymous
    @title = 'ваши анонимки'
    @entries = current_site.entries.anonymous.for_view.paginate :page => params[:page], :per_page => Entry::PAGE_SIZE
    render :action => 'private'
  end

  # Вывести текущую запись
  def show
    @comments = Rails.cache.fetch("comments_#{@entry.id}_#{@entry.comments_count}_#{@entry.updated_at.to_i}", :expires_in => 1.day) { @entry.comments.all(:include => { :user => :avatar }, :order => 'comments.id').reject { |comment| comment.user.nil? } }

    @last_comment_viewed = current_user ? CommentViews.view(@entry, current_user) : 0
    @time = @entry.created_at
  end
  
  #
  # Helper and AJAX methods
  #

  # show tags & related metadata
  def metadata
    render :partial => 'metadata', :locals => { :entry => @entry }
  end
  
  # show tags cloud
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
  
  def next_day
    @entries = current_site.recent_entries(:time => @time)

  	d = @entries.first.next.created_at rescue nil

    redirect_to d ? user_url(current_site, day_path(:year => d.year, :month => d.month, :day => d.mday)) : user_url(current_site)
  end
  
  def prev_day
    @entries = current_site.recent_entries(:time => @time)

  	d = @entries.last.prev.created_at rescue nil

    redirect_to d ? user_url(current_site, day_path(:year => d.year, :month => d.month, :day => d.mday)) : user_url(current_site)
  end
  
  # удаляет запись из тлога
  def destroy
    url = tlog_url_for_entry(@entry)
    if @entry.is_anonymous?
      flash[:bad] = 'Извините, к сожалению, анонимки нельзя удалять'
    else
      # async is not working properly yet
      # @entry.async_destroy!
      @entry.destroy
      
      flash[:good] = 'Запись была удалена'
    end

    redirect_to url
  end
  
  def foaf
    response.headers['Content-Type'] = 'application/rdf+xml'
    
    render :layout => false
  end
  
  def style
    expires_in 1.year, :public => true    

    response.headers['Content-Type'] = 'text/css'
    
    render :layout => false
    
  end
  
  def robots
    expires_in 15.days, :public => true

    render :file => 'tlog/robots.txt'
  end
  
  private
    # mark tlog as viewed by current visitor
    def mark_as_viewed
      current_site.mark_as_viewed_by!(current_user, @entry)
      
      true
    end
  
    # protect empty or private tlogs with no public entries from being visited
    def taken_but_empty
      render_tasty_404("Этот имя занято, но пользователь еще не сделал ни одной записи.<br/>Загляните, пожалуйста, позже.<br/><br/><a href='#{current_service.url}'>&#x2190; вернуться на главную</a>") and return false if current_site.entries_count_for(current_user).zero? && !is_owner?
      
      true      
    end
    
    def set_time
      @time = [params[:year], params[:month], params[:day]].join('-').to_date.to_time
      redirect_to user_url(current_site) and return if @time.nil?
      
      true
    end

    def check_if_can_be_viewed
      render :action => 'hidden' and return false unless current_site.can_be_viewed_by?(current_user)
    end
    
    def check_if_entry_can_be_viewed
      render :action => 'hidden' and return false unless @entry.can_be_viewed_by?(current_user)
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
