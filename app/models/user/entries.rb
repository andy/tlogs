class User
  ## included modules & attr_*
  attr_accessible :entries_updated_at


  ## associations
  ## plugins
  ## named_scopes
  ## validations
  ## callbacks
  ## class methods
  ## public methods
  
  # количество записей для пользователя user. либо entries_count, либо public_entries_count
  def entries_count_for(user = nil)
    (user && self.id == user.id) ? self.entries_count : self.public_entries_count
  end
  
  def new_entries_count_for(user = nil)
    if user
      relationship = user.relationship_with(self)
      !!relationship ? self.entries_count_for(user) - relationship.last_viewed_entries_count : 0
    else
      0
    end
  end
  
  # количество публичных записей (т.е. видимых всем)
  def public_entries_count
    self.entries_count - self.private_entries_count
  end
  
  # время когда была написана последняя запись
  # TODO: добавить кеширование только для случаев, когда есть публичные записи (public_entries_count.nonzero?)
  def last_public_entry_at
    @last_public_entry_at ||= Entry.find_by_sql("SELECT id, created_at FROM entries WHERE user_id = #{self.id} AND is_private = 0 ORDER BY entries.id DESC LIMIT 1").first.created_at rescue Time.now
  end
  
  # время, когда была написана первая запись
  # TODO: добавить кеширование только для случаев, когда есть публичные записи (public_entries_count.nonzero?)
  def first_public_entry_at
    @first_public_entry_at ||= Entry.find_by_sql("SELECT id, created_at FROM entries WHERE user_id = #{self.id} AND is_private = 0 ORDER BY entries.id ASC LIMIT 1").first.created_at rescue Time.now
  end
  
  # возвращает список текущих записей для пользователя, возможные параметры:
  #   page - текущая страница
  #   page_size - количество записей на странице
  #   include_private - включать ли закрытые записи
  #   only_private - только скрытые записи
  #   only_ids - возвращает только ID записей, без других полей
  def recent_entries(options = {})
    options[:page]        = 1 if !options.has_key?(:page) || options[:page] <= 0
    options[:page_size]   = Entry::PAGE_SIZE if !options.has_key?(:page_size) || options[:page_size] <= 0
    include_private       = options[:include_private] || false
    only_private          = options[:only_private] || false
    only_ids              = options[:only_ids] || false
    include_private     ||= true if only_private
    
    e_count               = only_private ? self.private_entries_count : (include_private ? self.entries_count : self.public_entries_count)
    e_count               = 0 if e_count < 0

    conditions = []
    conditions << 'entries.is_private = 0' unless include_private
    conditions << 'entries.is_private = 1' if only_private
    conditions << "entries.created_at BETWEEN '#{options[:time].strftime("%Y-%m-%d")}' AND '#{options[:time].tomorrow.strftime("%Y-%m-%d")}'" if options[:time]
    conditions << "entries.type = '#{options[:type]}'" if options[:type]
    conditions = conditions.blank? ? nil : conditions.join(' AND ')

    find_options = { :order => 'entries.id DESC', :include => [:author, :attachments, :rating], :conditions => conditions }
    # find_options[:page] = { :current => options[:page], :size => options[:page_size], :count => e_count } unless options[:time]

    WillPaginate::Collection.create(options[:page], options[:per_page] || Entry::PAGE_SIZE, e_count.zero? ? nil : e_count) do |pager|
      entry_ids = entries.find(:all, find_options.slice(:conditions, :order).merge(:select => 'entries.id, entries.user_id, entries.is_private', :limit => pager.per_page, :offset => pager.offset)).map(&:id)

      if only_ids
        pager.replace(entry_ids)
      else
        result = Entry.find_all_by_id(entry_ids, find_options.slice(:include)).sort_by { |entry| entry_ids.index(entry.id) }
        pager.replace(result)
      end
      
      pager.total_entries = entries.count(find_options.slice(:conditions)) unless pager.total_entries
    end
  end

  def self.entries_with_views_for(entry_ids, user = nil, options = {})
    result = Entry.find_all_by_id(entry_ids, :select => 'entries.id, entries.comments_count').sort_by { |entry| entry_ids.index(entry.id) }
    
    if user
      # update virtual attribute
      views = CommentViews.find(:all, :conditions => ['user_id = ? AND entry_id IN (?)', user.id, result.map(&:id)])
    
      views.each do |view|
        result.find { |entry| entry.id == view.entry_id }.last_comment_viewed = view.last_comment_viewed
      end
      # result.each { |entry| entry.last_comment_viewed = views.find { |view| view.entry_id == entry.id }.last_comment_viewed }
    end

    result
  end
  
  # ID последних записей ПЛЮС количество комментариев с количеством просмотров для пользователя user
  def recent_entries_with_views_for(user=nil, options = {})
    entry_ids = recent_entries(options.merge(:only_ids => true))

    result = Entry.find_all_by_id(entry_ids, :select => 'entries.id, entries.comments_count').sort_by { |entry| entry_ids.index(entry.id) }
    
    if user
      # update virtual attribute
      views = CommentViews.find(:all, :conditions => ['user_id = ? AND entry_id IN (?)', user.id, entry_ids])
    
      views.each do |view|
        result.find { |entry| entry.id == view.entry_id }.last_comment_viewed = view.last_comment_viewed
      end
      # result.each { |entry| entry.last_comment_viewed = views.find { |view| view.entry_id == entry.id }.last_comment_viewed }
    end
    
    result
    # 
    # page            = (options[:page] || 1).to_i
    # include_private = options[:include_private] || false
    # 
    # conditions_sql = " WHERE e.user_id = #{self.id}"
    # conditions_sql += " AND e.is_private = 0" unless include_private
    # if user
    #   entries.find_by_sql("SELECT e.id,e.comments_count,v.last_comment_viewed FROM entries e LEFT JOIN comment_views AS v ON v.entry_id = e.id AND v.user_id = #{user.id} #{conditions_sql} ORDER BY e.id DESC LIMIT #{(page > 0 ? (page - 1) : 0)  * Entry::PAGE_SIZE}, #{Entry::PAGE_SIZE}")
    # else
    #   entries.find_by_sql("SELECT id,comments_count FROM entries e #{conditions_sql} ORDER BY e.id DESC LIMIT #{(page > 0 ? (page - 1) : 0)  * Entry::PAGE_SIZE}, #{Entry::PAGE_SIZE}")
    # end
  end
  
  ## private methods  
  

end
