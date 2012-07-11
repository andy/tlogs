class MainController < ApplicationController
  skip_before_filter :require_confirmation_on_current_user
  
  before_filter :require_current_user, :only => [:worst, :demote]
  
  before_filter :require_moderator, :only => [:demote]
  
  before_filter :enable_shortcut, :only => [:news, :hot, :last, :hot, :live, :my, :worst, :tagged, :last_personalized, :random, :faves]
  
  protect_from_forgery :only => :demote


  def index
  end
  
  def about
  end
  
  def adv
  end
  
  def stats
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
    
    render :layout => false if should_xhr?
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
    rating = (current_user && current_user.settings[:last_rating]) || 'great' if rating == 'default'
  
    kind = 'any' unless Entry::KINDS.include?(kind.to_sym)
    rating = 'great' unless EntryRating::RATINGS.include?(rating.to_sym)
    
    @filter = Struct.new(:kind, :rating).new(kind, rating)
    
    @time = Date.today

    page = current_page
    
    if params[:year]
      sql_conditions = [EntryRating::RATINGS[@filter.rating.to_sym][:filter], Entry::KINDS[@filter.kind.to_sym][:filter]].join(' AND ')
      
      @time = [params[:year], params[:month], params[:day]].join('-').to_date.to_time rescue Date.today
      sql_conditions += " AND entry_ratings.created_at BETWEEN '#{@time.strftime("%Y-%m-%d")}' AND '#{@time.tomorrow.strftime("%Y-%m-%d")}'"

      @pager = EntryRating.paginate(:all,
                              :select     => 'entry_ratings.entry_id',
                              :page       => page,
                              :per_page   => Entry::PAGE_SIZE,
                              :order      => 'entry_ratings.hotness DESC, entry_ratings.id DESC',
                              :conditions => sql_conditions
                            )
      entry_ids = @pager.map(&:entry_id)
    else
      qkey      = [rating, kind == 'any' ? nil : "#{kind}_entry"].compact.join(':')
      @pager    = EntryQueue.new(qkey).paginate(:page => page)
      entry_ids = @pager
    end

    @entries  = Entry.find_all_by_id(entry_ids, :include => [:author, :rating, { :attachments => :thumbnails }]).sort_by { |entry| entry_ids.index(entry.id) }
    
    @entries.reject! { |entry| current_user.blacklist_ids.include?(entry.user_id) } if current_user && current_user.is_premium?
    
    @comment_views = User::entries_with_views_for(entry_ids, current_user)
    
    render :layout => false if should_xhr?
  end
  
  def demote
    @entry = Entry.find(params[:id])
    
    @entry.rating.send(:dequeue)
    
    queue = EntryQueue.new('demoted')
    queue.push @entry.id
    
    @entry.author.log current_user, :entry_hide, params[:comment], @entry

    render :json => true
  end
  
  def worst
    @pager    = EntryQueue.new('worst').paginate(:page => current_page)
    entry_ids = @pager

    @entries = Entry.find_all_by_id(entry_ids, :include => [:author, :rating, { :attachments => :thumbnails }]).sort_by { |entry| entry_ids.index(entry.id) }
    
    @entries.reject! { |entry| current_user.blacklist_ids.include?(entry.user_id) } if current_user && current_user.is_premium?

    @comment_views = User::entries_with_views_for(entry_ids, current_user)
    
    render :layout => false if should_xhr?
  end
  
  def hot
    # подгружаем
    @kind = params[:kind] || 'default'
    @kind = 'any' unless Entry::KINDS.include?(@kind.to_sym)

    sql_conditions = Entry::KINDS[@kind.to_sym][:filter]

    @entry_ratings = EntryRating.paginate :all, :page => current_page, :per_page => Entry::PAGE_SIZE, :include => { :entry => [ :author, :rating, { :attachments => :thumbnails } ] }, :order => 'entry_ratings.hotness DESC, entry_ratings.id DESC', :conditions => sql_conditions
    
    @entry_ratings.reject! { |rating| current_user.blacklist_ids.include?(rating.entry.user_id) } if current_user && current_user.is_premium?
    
    @comment_views = User::entries_with_views_for(@entry_ratings.map(&:entry_id), current_user)
    
    render :layout => false if should_xhr?
  end
  
  def live
    @title      = 'прямой эфир как он есть'
    
    queue       = EntryQueue.new('live')
    entry_id    = params[:page].to_i if params[:page]
    entry_ids   = (entry_id && entry_id > 0) ? queue.after(entry_id) : queue.page(1)
    
    @entries    = Entry.find_all_by_id(entry_ids, :include => [:author, :rating, { :attachments => :thumbnails }]).sort_by { |entry| entry_ids.index(entry.id) }
    
    @entries.reject! { |entry| current_user.blacklist_ids.include?(entry.user_id) } if current_user && current_user.is_premium?
    
    @comment_views = User::entries_with_views_for(@entries.map(&:id), current_user)
    
    render :layout => false if should_xhr?
  end
  
  def tagged
    total = Entry.count_tagged_with(params[:tag], :is_mainpageable => true)

    @page = params[:page].to_i rescue 1
    @page = 1 if @page.zero?

    # grab id-s only, this is an mysql optimization
    @entries = WillPaginate::Collection.create(@page, Entry::PAGE_SIZE, total) do |pager|
      result = Entry.paginate_by_category(params[:tag], { :total => total, :page => pager.current_page }, { :is_mainpageable => true })
    
      pager.replace(result.to_a)
    
      pager.total_entries = total unless pager.total_entries
    end
    
    popular_tag_ids = Tagging.all(:limit => 1000, :order => 'id desc').group_by(&:tag_id).sort_by { |k, v| -v.length }[0..20].map(&:first)
    @popular_tags = Tag.find_all_by_id(popular_tag_ids).sort_by { |tag| popular_tag_ids.index(tag.id) }
    
    @comment_views = User::entries_with_views_for(@entries.map(&:id), current_user)
    
    render :layout => false if should_xhr?
  end
  
  def my
    @title = 'моё'

    redirect_to(service_url(login_path)) and return unless current_user
    
    @page = current_page    

    @entries = WillPaginate::Collection.create(@page, Entry::PAGE_SIZE, current_user.my_entries_queue_length) do |pager|
      entry_ids = current_user.my_entries_queue(pager.offset, pager.per_page)
      result    = Entry.find_all_by_id(entry_ids, :include => [:author, :rating, { :attachments => :thumbnails }]).sort_by { |entry| entry_ids.index(entry.id) }
      
      pager.replace(result.to_a)
      
      pager.total_entries = $redis.zcard(current_user.queue_key) unless pager.total_entries
    end
    
    @comment_views = User::entries_with_views_for(@entries.map(&:id), current_user)
    
    @stats = Rails.cache.fetch(["main", "my", "stats", current_user.id].join(':'), :expires_in => 15.minutes) do
      result              = OpenStruct.new
      result.days         = (Time.now - current_user.created_at).to_i / 1.day
      result.faves_count  = Fave.count(:conditions => "entry_user_id = #{current_user.id} AND created_at > '#{24.hours.ago.to_time.to_s(:db)}'")
      
      result
    end
    
    
    render :layout => false if should_xhr?
  end
  
  def faves
    @title      = 'избранное друзей'
    @page       = current_page

    friend_ids  = current_user.readable_friend_ids
    
    unless friend_ids.blank?
      @entry_ids  = Fave.paginate :all, :select => 'faves.entry_id AS id', :conditions => "faves.user_id IN (#{friend_ids.join(',')})",  :group => :entry_id, :order => 'faves.entry_id DESC', :page => @page, :per_page => Entry::PAGE_SIZE
      @entries    = Entry.find_all_by_id @entry_ids.map(&:id), :include => [:rating, :author, { :attachments => :thumbnails }], :order => 'entries.id DESC'

      @comment_views = User::entries_with_views_for(@entries.map(&:id), current_user)
    end

    render :layout => false if should_xhr?    
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
      @entries    = Entry.find_all_by_id @entry_ids.map(&:id), :include => [:rating, :author, { :attachments => :thumbnails }], :order => 'entries.id DESC'
      
      @comment_views = User::entries_with_views_for(@entries.map(&:id), current_user)
    end
    
    render :layout => false if should_xhr?
  end
  
  def users
    @users = User.active_for(current_user, :limit => 20, :popularity => 2)
    @title = 'пользователи в абсолютно случайной последовательности'
  end
  
  def new_users
    @page  = current_page
    @users = User.paginate(:page => @page, :per_page => 6, :include => [:tlog_settings], :order => 'users.id DESC', :conditions => 'users.is_confirmed = 1 AND users.entries_count > 0')
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