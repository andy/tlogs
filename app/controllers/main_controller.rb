class MainController < ApplicationController
  skip_before_filter :require_confirmation_on_current_user

  def index
  end
  
  def about
  end
  
  def news
    news = User.find_by_url('news')
    
    # обновляем статистику для текущего пользователя
    if current_user && news.entries_count > 0 && !is_owner?
      rel = current_user.reads(news)
      # обновляем количество просмотренных записей, если оно изменилось
      if news.entries_count_for(current_user) != rel.last_viewed_entries_count
        rel.last_viewed_at = Time.now
        rel.last_viewed_entries_count = news.entries_count_for(current_user)
        rel.save!
      end
    end
    
    total_pages = news.entries_count_for(news).to_pages
    @page = params[:page].to_i.reverse_page( total_pages ) rescue 1
    @entries = news.recent_entries({ :page => @page })
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
    
    # высчитываем общее число записей и запоминаем в кеше
    total = Rails.cache.fetch("entry_ratings_count_#{kind}_#{rating}", :expires_in => 1.minute) { EntryRating.count :conditions => sql_conditions }

    @entry_ratings = EntryRating.find :all, :page => { :current => params[:page].to_i.reverse_page(total.to_pages), :size => 15, :count => total }, :include => { :entry => [ :attachments, :author, :rating ] }, :order => 'entry_ratings.id DESC', :conditions => sql_conditions
  end
  
  def live
    sql_conditions = 'entries.is_mainpageable = 1'
    
    # кешируем общее число записей, потому что иначе :page обертка будет вызывать счетчик на каждый показ
    total = Rails.cache.fetch('entry_count_public', :expires_in => 1.minute) { Entry.count :conditions => sql_conditions }

    @page = params[:page].to_i.reverse_page(total.to_pages)

    # grab id-s only, this is an mysql optimization
    @entry_ids = Entry.find :all, :select => 'entries.id', :conditions => sql_conditions, :page => { :current => @page, :size => Entry::PAGE_SIZE, :count => total }, :order => 'entries.id DESC'
    @entries = Entry.find_all_by_id @entry_ids.map(&:id), :include => [:author, :rating, :attachments], :order => 'entries.id DESC'
  end
  
  def last_personalized
    redirect_to(service_url(last_path)) and return unless current_user

    # такая же штука определена в tlog_feed_controller.rb
    friend_ids = current_user.all_friend_r.map(&:user_id)
    unless friend_ids.blank?
      @page = params[:page].to_i rescue 1
      @page = 1 if @page <= 0
      # еще мы тут обманываем с количеством страниц... потому что считать тяжело
      @entry_ids = Entry.find :all, :select => 'entries.id', :conditions => "entries.user_id IN (#{friend_ids.join(',')}) AND entries.is_private = 0", :order => 'entries.id DESC', :page => { :current => @page, :size => 15, :count => ((@page * 15) + 1) }
      @entries = Entry.find_all_by_id @entry_ids.map(&:id), :include => [:rating, :attachments, :author], :order => 'entries.id DESC'
    end
    expires_in 5.minutes
  end
  
  def users
    @users = User.popular(6).shuffle
    @title = 'пользователи в абсолютно случайной последовательности'
  end
  
  def new_users
    @users = User.paginate(:page => params[:page], :per_page => 6, :include => [:avatar, :tlog_settings], :order => 'users.id DESC', :conditions => 'users.is_confirmed = 1 AND users.entries_count > 0')
    @title = 'все пользователи тейсти'
    render :action => 'users'
  end
  
  def random
    # ищем публичную запись которую можно еще на главной показать
    entry = nil
    if params[:entry_id]
      entry = Entry.find_by_id params[:entry_id]
      redirect_to(service_url(main_path)) and return if entry.nil?
    end
      
    max_id = Entry.maximum(:id)
    unless entry
      10.times do
        entry_id = Entry.find_by_sql("SELECT id FROM entries WHERE id >= #{rand(max_id)} AND is_private = 0 LIMIT 1").first[:id]
        entry = Entry.find entry_id if entry_id
        break if entry
      end
    end
    if entry
      @time = entry.created_at
      @user = entry.author
      @entries = @user.recent_entries(:page => 1, :time => @time).to_a      
      @calendar = @user.calendar(@time)
      
      @others = User.find_by_sql("SELECT u.id, u.url, e.id AS day_first_entry_id, count(*) AS day_entries_count FROM users AS u LEFT JOIN entries AS e ON u.id = e.user_id WHERE e.created_at > '#{@time.midnight.to_s(:db)}' AND e.created_at < '#{@time.tomorrow.midnight.to_s(:db)}' AND u.is_confirmed = 1 AND u.entries_count > 1 GROUP BY e.user_id")
    end
  end
end