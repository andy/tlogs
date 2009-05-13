class User
  USER_AND_RELATIONSHIP_COLUMNS = 'u.*,r.title,r.friendship_status,r.read_count,r.comment_count,r.position,r.last_viewed_entries_count,r.last_viewed_at,r.id AS relationship_id'
  
  has_many :relationships, :dependent => :destroy
    
  # лишь хорошие друзья
  {
    :public_friends => { :filter => '= 2', :order => 'r.position' },
    :friends => { :filter => '= 1', :order => 'r.position' },
    :guessed_friends => { :filter => '= 0 AND r.read_count > 4', :order => 'r.read_count DESC' },
    :all_friends => { :filter => '> 0', :order => 'r.friendship_status DESC, r.position' },
    :everybody => { :filter => nil, :order => nil }
  }.each do |name, params|
    param_filter = params[:filter] ? " AND r.friendship_status #{params[:filter]}" : ''
    param_order = params[:order] ? " ORDER BY #{params[:order]}" : ''

    has_many name.to_sym, :class_name => 'User', :finder_sql => "SELECT #{USER_AND_RELATIONSHIP_COLUMNS} FROM relationships AS r LEFT JOIN users AS u ON u.id = r.user_id WHERE r.reader_id = \#{id} #{param_filter} #{param_order}"
    # e.g. public_friend_r (- relationship model)
    has_many "#{name.to_s.singularize}_r".to_sym, :class_name => 'Relationship', :finder_sql => "SELECT r.* FROM relationships AS r WHERE r.reader_id = \#{id} #{param_filter}"        
    # e.g. listed_me_as_public_friend (which means - get me my readers that have me listed as public friend)
    has_many "listed_me_as_#{name.to_s.singularize}".to_sym, :class_name => 'User', :finder_sql => "SELECT #{USER_AND_RELATIONSHIP_COLUMNS} FROM relationships AS r LEFT JOIN users AS u ON u.id = r.reader_id WHERE r.user_id = \#{id} #{param_filter} #{param_order}"
    # same as previous, but only a relationship model which is much lighter as it fetches only from relationships table and does not include User
    has_many "listed_me_as_#{name.to_s.singularize}_r".to_sym, :class_name => 'Relationship', :finder_sql => "SELECT r.* FROM relationships AS r WHERE r.user_id = \#{id} #{param_filter}"
  end
  
  # Пользователь user читает текущего пользователя
  def reads(user)
    return if self.id == user.id

    relationship = relationship_with(user, true)        
    do_save = relationship.new_record?
    relationship.friendship_status = Relationship::GUESSED if relationship.new_record?

    # абсолютных друзей не бывает, engeen
    if relationship.read_count < 20 && (!relationship.last_read_at || relationship.last_read_at < Math.exp(relationship.read_count).ago)
      relationship.increment(:read_count)
      relationship.last_read_at = Time.now
      do_save = true
    end

    relationship.save! if do_save
    relationship
  end

  def relationship_with(user, create = false)
    return false if self.id == user.id
    relationship = create ? \
      Relationship.find_or_initialize_by_user_id_and_reader_id(user.id, self.id) : \
      Relationship.find_by_user_id_and_reader_id(user.id, self.id)
    relationship.position = 0 if relationship && relationship.new_record?
    relationship
  end
  
  # то же самое что и relationship_with, но возвращает объект User с
  #  дополнительными полями из relationships
  def relationship_as_user_with(user)
    return if self.id == user.id
    result = User.find_by_sql "SELECT #{USER_AND_RELATIONSHIP_COLUMNS} FROM relationships AS r LEFT JOIN users AS u ON u.id = r.user_id WHERE r.user_id = #{user.id} AND r.reader_id = #{self.id} LIMIT 1"
    result[0] if result
  end
  
  def set_friendship_status_for(user, to = Relationship::DEFAULT)
    relationship = relationship_with(user, true)
    relationship.update_attributes!({ :friendship_status => to }) if relationship && relationship.friendship_status != to
    relationship
  end
  
  # Подписан ли на ленту пользоваетля user? Возвращает true / false
  def subscribed_to?(user)
    return false unless user
    (relationship = relationship_with(user)) && relationship.friendship_status >= Relationship::DEFAULT
  end

  # Пользователь user комментирует записи другого пользователя
  def comments(user)
    return if self.id == user.id
    relationship = Relationship.find_or_initialize_by_user_id_and_reader_id(user.id, self.id)
    relationship.increment(:comment_count)
    relationship.last_comment_at = Time.now
    relationship.save!
  end      
end