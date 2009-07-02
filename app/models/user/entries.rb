class User
  ## included modules & attr_*
  attr_accessible :entries_updated_at


  ## associations
  ## plugins
  ## named_scopes
  ## validations
  ## callbacks
  ## class methods
  def self.popular(limit = 6)
    user_ids = Rails.cache.fetch('Users.popular', :expires_in => 1.day) { User.find_by_sql("SELECT user_id AS id,count(*) AS c FROM relationships WHERE friendship_status > 0 GROUP BY user_id ORDER BY c DESC LIMIT 100") }
    User.find_all_by_id(user_ids.map(&:id).shuffle[0...limit], :include => [:avatar, :tlog_settings])
  end


  ## public methods
  
  # количество записей для пользователя user. либо entries_count, либо public_entries_count
  def entries_count_for(user = nil)
    (user && self.id == user.id) ? self.entries_count : self.public_entries_count
  end
  
  def new_entries_count_for(user = nil)
    if user
      relationship = user.relationship_with(self)
      relationship.nil? ? 0 : self.entries_count_for(user) - relationship.last_viewed_entries_count
    else
      0
    end
  end
  
  # количество публичных записей (т.е. видимых всем)
  def public_entries_count
    self.entries_count - self.private_entries_count
  end
  
  # время когда была написана последняя запись
  def last_public_entry_at
    # self.entries.public.last.created_at - the same?
    Entry.find_by_sql("SELECT id, created_at FROM entries WHERE user_id = #{self.id} AND is_private = 0 ORDER BY entries.id DESC LIMIT 1").first.created_at rescue Time.now
  end
  
  # возвращает список текущих записей для пользователя, возможные параметры:
  #   page - текущая страница
  #   page_size - количество записей на странице
  #   include_private - включать ли закрытые записи
  #   only_private - только скрытые записи
  def recent_entries(options = {})
    options[:page]        = 1 if !options.has_key?(:page) || options[:page] <= 0
    options[:page_size]   = Entry::PAGE_SIZE if !options.has_key?(:page_size) || options[:page_size] <= 0
    include_private       = options[:include_private] || false
    only_private          = options[:only_private] || false
    include_private     ||= true if only_private
    
    e_count               = only_private ? self.private_entries_count : (include_private ? self.entries_count : self.public_entries_count)
    e_count               = 0 if e_count < 0

    conditions = []
    conditions << 'entries.is_private = 0' unless include_private
    conditions << 'entries.is_private = 1' if only_private
    conditions << "entries.created_at BETWEEN '#{options[:time].strftime("%Y-%m-%d")}' AND '#{options[:time].tomorrow.strftime("%Y-%m-%d")}'" if options[:time]
    conditions = conditions.blank? ? nil : conditions.join(' AND ')

    find_options = { :order => 'entries.id DESC', :include => [:author, :attachments, :rating], :conditions => conditions }
    find_options[:page] = { :current => options[:page], :size => options[:page_size], :count => e_count } unless options[:time]

    entries.find(:all, find_options)
  end
  
  # ID последних записей ПЛЮС количество комментариев с количеством просмотров для пользователя user
  def recent_entries_with_views_for(user=nil, options = {})
    page            = (options[:page] || 1).to_i
    include_private = options[:include_private] || false

    conditions_sql = " WHERE e.user_id = #{self.id}"
    conditions_sql += " AND e.is_private = 0" unless include_private
    if user
      entries.find_by_sql("SELECT e.id,e.comments_count,v.last_comment_viewed FROM entries e LEFT JOIN comment_views AS v ON v.entry_id = e.id AND v.user_id = #{user.id} #{conditions_sql} ORDER BY e.id DESC LIMIT #{(page > 0 ? (page - 1) : 0)  * Entry::PAGE_SIZE}, #{Entry::PAGE_SIZE}")
    else
      entries.find_by_sql("SELECT id,comments_count FROM entries e #{conditions_sql} ORDER BY e.id DESC LIMIT #{(page > 0 ? (page - 1) : 0)  * Entry::PAGE_SIZE}, #{Entry::PAGE_SIZE}")
    end
  end
  
  def recent_entries_with_ratings(options = {})
    page            = (options[:page] || 1).to_i
    include_private = options[:include_private] || false

    conditions_sql = " WHERE e.user_id = #{self.id}"
    conditions_sql += " AND e.is_private = 0" unless include_private
    entries.find_by_sql("SELECT e.id,r.value FROM entries AS e LEFT JOIN entry_ratings AS r ON r.entry_id = e.id AND r.user_id = #{self.id} #{conditions_sql} ORDER BY e.id DESC LIMIT #{(page > 0 ? (page - 1) : 0)  * Entry::PAGE_SIZE}, #{Entry::PAGE_SIZE}")
  end
  
  ## private methods  
  

end