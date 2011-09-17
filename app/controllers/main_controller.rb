class MainController < ApplicationController
  skip_before_filter :require_confirmation_on_current_user
  
  before_filter :enable_shortcut, :only => [:news, :hot, :last, :hot, :live, :my, :last_personalized, :random]
  

  def index
  end
  
  def about
  end
  
  def premium
    redirect_to current_user ? user_url(current_user, settings_premium_path) : service_url(login_path(:ref => settings_premium_path))
  end
  
  def settings
    redirect_to current_user ? user_url(current_user, settings_path) : service_url(login_path(:ref => settings_path))
  end
  
  def publish
    redirect_to current_user ? user_url(current_user, publish_path(:action => params[:type])) : service_url(login_path(:ref => publish_path(:action => params[:type])))
  end
  
  def news
    news = User.find_by_url('news')    
    news.mark_as_viewed_by!(current_user)

    @page           = current_page
    @entries        = news.recent_entries({ :page => @page })    
    @comment_views  = User::entries_with_views_for(@entries.map(&:id), current_user)
    
    render :layout => false if request.xhr?
  end
  
  def last_redirect
    kind = params[:filter][:kind]
    rating = params[:filter][:rating]

    kind = 'any' unless Entry::KINDS.include?(kind.to_sym)
    rating = 'everything' unless EntryRating::RATINGS.include?(rating.to_sym)

    if current_user
      current_user.settings_will_change!
      current_user.settings[:last_kind] = kind
      current_user.settings[:last_rating] = rating
      current_user.save
    end
    redirect_to service_url(last_path(:kind => kind, :rating => rating))
  end
  
  def hot_redirect
    kind = params[:kind]
    kind = 'any' unless Entry::KINDS.include?(kind.to_sym)

    redirect_to service_url(hot_path(:kind => kind))
  end
  
  def last
    # подгружаем
    kind = params[:kind] || 'default'
    rating = params[:rating] || 'default'  
    
    # выставляем значения по-умолчанию
    kind = (current_user && current_user.settings[:last_kind]) || 'any' if kind == 'default'
    rating = (current_user && current_user.settings[:last_rating]) || 'good' if rating == 'default'
  
    kind = 'any' unless Entry::KINDS.include?(kind.to_sym)
    rating = 'good' unless EntryRating::RATINGS.include?(rating.to_sym)

    @filter = Struct.new(:kind, :rating).new(kind, rating)
    sql_conditions = "#{EntryRating::RATINGS[@filter.rating.to_sym][:filter]} AND #{Entry::KINDS[@filter.kind.to_sym][:filter]}"
    
    @time = Date.today
    # высчитываем общее число записей и запоминаем в кеше
    # total = Rails.cache.fetch("entry_ratings_count_#{kind}_#{rating}", :expires_in => 1.minute) { EntryRating.count :conditions => sql_conditions }

    page = current_page
    
    if params[:year]
      @time = [params[:year], params[:month], params[:day]].join('-').to_date.to_time rescue Date.today
      sql_conditions += " AND entry_ratings.created_at BETWEEN '#{@time.strftime("%Y-%m-%d")}' AND '#{@time.tomorrow.strftime("%Y-%m-%d")}'"
      @entry_ratings = EntryRating.paginate :all, :page => page, :per_page => Entry::PAGE_SIZE, :include => { :entry => [ :attachments, :author, :rating ] }, :order => 'entry_ratings.hotness DESC, entry_ratings.id DESC', :conditions => sql_conditions
    else
      @entry_ratings = EntryRating.paginate :all, :page => page, :per_page => Entry::PAGE_SIZE, :include => { :entry => [ :attachments, :author, :rating ] }, :order => 'entry_ratings.id DESC', :conditions => sql_conditions
    end
    
    @comment_views = User::entries_with_views_for(@entry_ratings.map(&:entry_id), current_user)
    
    render :layout => false if request.xhr?
  end
  
  def hot
    # подгружаем
    @kind = params[:kind] || 'default'
    @kind = 'any' unless Entry::KINDS.include?(@kind.to_sym)

    sql_conditions = Entry::KINDS[@kind.to_sym][:filter]

    @entry_ratings = EntryRating.paginate :all, :page => current_page, :per_page => Entry::PAGE_SIZE, :include => { :entry => [ :attachments, :author, :rating ] }, :order => 'entry_ratings.hotness DESC, entry_ratings.id DESC', :conditions => sql_conditions
    
    @comment_views = User::entries_with_views_for(@entry_ratings.map(&:entry_id), current_user)
    
    render :layout => false if request.xhr?
  end
  
  def live
    @title     = 'прямой эфир как он есть'

    entry_id   = params[:page].to_i if params[:page]
    entry_id ||= Entry.mainpageable.last.id + 1

    entry_ids = Entry.mainpageable.find(:all, :select => 'entries.id', :conditions => "entries.id < #{entry_id}", :order => 'entries.id DESC', :limit => Entry::PAGE_SIZE).map(&:id)
    @entries = Entry.find_all_by_id(entry_ids, :include => [:author, :rating, :attachments]).sort_by { |entry| entry_ids.index(entry.id) }

    @comment_views = User::entries_with_views_for(@entries.map(&:id), current_user)
    
    render :layout => false if request.xhr?
  end
  
  def my
    @title = 'моё'

    redirect_to(service_url(login_path)) and return unless current_user
    
    @page = current_page    

    @entries = WillPaginate::Collection.create(@page, Entry::PAGE_SIZE, current_user.my_entries_queue_length) do |pager|
      entry_ids = current_user.my_entries_queue(pager.offset, pager.per_page)
      result = Entry.find_all_by_id(entry_ids, :include => [:author, :rating, :attachments]).sort_by { |entry| entry_ids.index(entry.id) }
      
      pager.replace(result.to_a)
      
      pager.total_entries = $redis.zcount unless pager.total_entries
    end
    
    @comment_views = User::entries_with_views_for(@entries.map(&:id), current_user)
    
    render :layout => false if request.xhr?
  end
  
  def last_personalized
    redirect_to(service_url(main_path(:action => :live))) and return unless current_user

    @title  = "ваш личный прямой эфир, #{current_user.url}"
    @page   = current_page

    # такая же штука определена в tlog_feed_controller.rb
    friend_ids = current_user.readable_friend_ids
    
    unless friend_ids.blank?
      # еще мы тут обманываем с количеством страниц... потому что считать тяжело
      @entry_ids  = Entry.paginate :all, :select => 'entries.id', :conditions => "entries.user_id IN (#{friend_ids.join(',')}) AND entries.is_private = 0", :order => 'entries.id DESC', :page => @page, :per_page => Entry::PAGE_SIZE
      @entries    = Entry.find_all_by_id @entry_ids.map(&:id), :include => [:rating, :attachments, :author], :order => 'entries.id DESC'
      
      @comment_views = User::entries_with_views_for(@entries.map(&:id), current_user)
    end
    
    render :layout => false if request.xhr?
  end
  
  def users
    @users = User.popular(20).shuffle
    @title = 'пользователи в абсолютно случайной последовательности'
  end
  
  def new_users
    @page  = current_page
    @users = User.paginate(:page => @page, :per_page => 6, :include => [:avatar, :tlog_settings], :order => 'users.id DESC', :conditions => 'users.is_confirmed = 1 AND users.entries_count > 0')
    @title = 'все пользователи тейсти'
    render :action => 'users'
  end
  
  def fl
    redirect_to(service_url(login_path)) and return unless current_user    
  end
  
  def random
    # ищем публичную запись которую можно еще на главной показать
    entry = nil
    if params[:entry_id]
      entry = Entry.find_by_id(params[:entry_id])
      
      redirect_to(service_url) and return if entry.nil? || entry.is_disabled? || entry.is_private? || entry.author.is_disabled?
      
      redirect_to(service_url) and return if %w(fr me).include?(entry.author.tlog_settings.privacy)
      
      redirect_to(service_url) and return if entry.author.tlog_settings.privacy == 'rr' && !current_user
      
    # elsif current_user
    #   entry = current_user.entries.last
    #   redirect_to(service_url) and return if entry.nil?
    else
      max_id = Entry.maximum(:id)
      unless entry
        10.times do
          entry_id = Entry.find_by_sql("SELECT id FROM entries WHERE id >= #{rand(max_id)} AND is_private = 0 AND is_mainpageable = 1 LIMIT 1").first[:id]
          entry = Entry.find(entry_id, :include => :author) if entry_id
          
          next if entry.author.is_disabled?
          
          next if %w(fr me).include?(entry.author.tlog_settings.privacy)
          
          next if entry.author.tlog_settings.privacy == 'rr' && !current_user

          # Rails.logger.debug "#{entry.author.url} c #{entry.author.is_confirmed}, d #{entry.author.is_disabled?}, m #{entry.author.is_mainpageable?}"
          # entry = nil if entry.author.is_disabled? || !entry.author.is_confirmed? || !entry.author.is_mainpageable?
          break if entry
        end
      end
    end

    if entry
      @time = entry.created_at
      @user = entry.author
      @entries = @user.recent_entries(:page => 1, :time => @time).to_a      
      @comment_views = User::entries_with_views_for(@entries.map(&:id), current_user)
      @calendar = @user.calendar(@time)
      
      # @others = User.find_by_sql("SELECT u.id, u.url, e.id AS day_first_entry_id, count(*) AS day_entries_count FROM users AS u LEFT JOIN entries AS e ON u.id = e.user_id WHERE e.created_at > '#{@time.midnight.to_s(:db)}' AND e.created_at < '#{@time.tomorrow.midnight.to_s(:db)}' AND u.is_confirmed = 1 AND u.is_disabled = 0 AND u.entries_count > 1 GROUP BY e.user_id")
    else  
      redirect_to service_url
    end
  end
  
  def robots
    render :file => 'main/robots.txt'
  end
end