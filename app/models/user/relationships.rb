class User
  ## included modules & attr_*
  USER_AND_RELATIONSHIP_COLUMNS = 'u.*,r.title,r.friendship_status,r.read_count,r.comment_count,r.position,r.last_viewed_entries_count,r.last_viewed_at,r.id AS relationship_id'


  ## associations
  has_many :relationships, :dependent => :destroy

    
  # лишь хорошие друзья
  {
    :public_friends   => { :filter => '= 2', :order => 'r.position' },
    :friends          => { :filter => '= 1', :order => 'r.position' },
    :guessed_friends  => { :filter => '= 0 AND r.read_count > 4', :order => 'r.read_count DESC' },
    :all_friends      => { :filter => '> 0', :order => 'r.friendship_status DESC, r.position' },
    :blacklist        => { :filter => '= -2', :order => 'r.position' },
    :everybody        => { :filter => nil, :order => nil }
  }.each do |name, params|
    param_filter    = params[:filter] ? " AND r.friendship_status #{params[:filter]}" : ''
    param_order     = params[:order] ? " ORDER BY #{params[:order]}" : ''

    has_many name.to_sym, :class_name => 'User', :finder_sql => "SELECT #{USER_AND_RELATIONSHIP_COLUMNS} FROM relationships AS r LEFT JOIN users AS u ON u.id = r.user_id WHERE r.reader_id = \#{id} #{param_filter} #{param_order}"
    # e.g. public_friend_r (- relationship model)
    has_many "#{name.to_s.singularize}_r".to_sym, :class_name => 'Relationship', :finder_sql => "SELECT r.* FROM relationships AS r WHERE r.reader_id = \#{id} #{param_filter}"        
    # e.g. listed_me_as_public_friend (which means - get me my readers that have me listed as public friend)
    has_many "listed_me_as_#{name.to_s.singularize}".to_sym, :class_name => 'User', :finder_sql => "SELECT #{USER_AND_RELATIONSHIP_COLUMNS} FROM relationships AS r LEFT JOIN users AS u ON u.id = r.reader_id WHERE r.user_id = \#{id} #{param_filter} #{param_order}"
    # same as previous, but only return ids
    has_many "listed_me_as_#{name.to_s.singularize}_light".to_sym, :class_name => 'User', :finder_sql => "SELECT u.id FROM relationships AS r LEFT JOIN users AS u ON u.id = r.reader_id WHERE r.user_id = \#{id} #{param_filter} #{param_order}"
    # same as previous, but only a relationship model which is much lighter as it fetches only from relationships table and does not include User
    has_many "listed_me_as_#{name.to_s.singularize}_r".to_sym, :class_name => 'Relationship', :finder_sql => "SELECT r.* FROM relationships AS r WHERE r.user_id = \#{id} #{param_filter}"
  end


  ## plugins
  ## named_scopes
  ## validations
  ## callbacks
  ## class methods
  ## public methods  
  # Пользователь user читает текущего пользователя
  def reads(user)
    return if self.id == user.id

    relationship = relationship_with(user, false)        
    do_save = relationship.new_record?
    relationship.friendship_status = Relationship::GUESSED if relationship.new_record?

    # абсолютных друзей не бывает, engeen
    if relationship.read_count < 20 && (!relationship.last_read_at || relationship.last_read_at < Math.exp(relationship.read_count).ago)
      relationship.increment(:read_count)
      relationship.last_read_at = Time.now
      do_save = true
    end

    begin
      relationship.save! if do_save
    rescue ActiveRecord::StatementInvalid
      # ignore duplicate key errors
      # Mysql::Error: Duplicate entry '11848-11133' for key 2: INSERT INTO `relationships` (`friendship_status`, `title`, `last_viewed_entries_count`, `comment_count`, `reader_id`, `last_viewed_at`, `last_comment_at`, `user_id`, `last_read_at`, `position`, `votes_value`, `read_count`) VALUES(0, NULL, 0, 0, 11133, NULL, NULL, 11848, '2009-12-04 18:57:19', 781, 0, 1)
      relationship.reload
    end

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
    (relationship = relationship_with(user)) && relationship.positive?
  end

  # Пользователь user комментирует записи другого пользователя
  def comments(user)
    return if self.id == user.id
    relationship = Relationship.find_or_initialize_by_user_id_and_reader_id(user.id, self.id)
    relationship.increment(:comment_count)
    relationship.last_comment_at = Time.now
    relationship.save!
  end
  
  # Возвращает user_id пользователей, на тлоги которых подписан текущий пользователь и 
  # которые он может читать (т.е. они не закрытые и т.п.)
  def readable_friend_ids
    @readable_friend_ids ||= Rails.cache.fetch("u:rel:rfi:#{self.id}", :expires_in => 1.hour) do
      ids = self.all_friend_r.map(&:user_id)
      if ids.any?
        ts  = TlogSettings.all(:select => 'id, user_id, privacy', :conditions => "user_id IN (#{ids.join(',')}) AND privacy != 'me'")
      
        # выбрасываем тех, у кого закрытый тлог и кто на нас не подписан
        ids = ts.reject { |t| t.privacy == 'fr' && !t.user.subscribed_to?(self) }.map(&:user_id)
      end
      
      ids
    end
  end
  
  #
  # current_site.mark_as_viewed_by! current_user
  #
  def mark_as_viewed_by!(user, entry = nil)
    # user?
    return if user.nil?

    # is_owner?
    return if user.id == self.id
    
    Rails.logger.debug "** mark_as_viewed_by #{self.url} by #{user.url}, entry #{entry.try(:id) || 'nil'}"
    
    # get relationship between the two
    Relationship.transaction do
      relationship = user.relationship_with(self, true)
      relationship.friendship_status = Relationship::GUESSED if relationship.new_record?
      
      Rails.logger.debug "** mark_as_viewed_by relationship #{relationship.try(:id) || 'nil'}, #{relationship.new_record? ? 'new' : 'existing'}"
      
      # positive relationship is one when user is explicitly or implicitly following another
      if relationship.positive?
        actual_entries_count = self.entries_count_for(user)
        viewed_entries_count = relationship.last_viewed_entries_count
        
        Rails.logger.debug "** mark_as_viewed_by aec #{actual_entries_count} vec #{viewed_entries_count}"
      
        if actual_entries_count != viewed_entries_count
          # if user is looking at specific entry, act a bit differently:
          if entry
            # stamp with current visit time / counters if this is first visit to the tlog
            if relationship.last_viewed_at.nil?
              Rails.logger.debug "** mark_as_viewed_by stamp to #{actual_entries_count}"
              relationship.stamp actual_entries_count

            # otherwise act as if only one record has been viewed out of all unviewed
            elsif entry.created_at > relationship.last_viewed_at && actual_entries_count > viewed_entries_count
              Rails.logger.debug "** mark_as_viewed_by increment (soft)"
              
              relationship.increment :last_viewed_entries_count
            end
        
          # if we are looking at tlog as a whole, without any specific entry, then just
          # update the timestamps and counters  
          else
            Rails.logger.debug "** mark_as_viewed_by stamp to #{actual_entries_count}"
            relationship.stamp actual_entries_count
          end        
        else
          Rails.logger.debug "** mark_as_viewed_by counters unchanged"
        end
    
      # negative relationship is when user is explicitly or implicitly ignoring another user
      else
        Rails.logger.debug "** mark_as_viewed_by negative, ignored"
    
      end # if/else relationship.positive?
      
      Rails.logger.debug "** mark_as_viewed_by save!"
      relationship.save!
    end # Relationship.transaction
    
    Rails.logger.debug "** mark_as_viewed_by done"
  end
  
  # this removes all people that are subscribed to my tlog
  def remove_subscribers!
    Relationship.delete_all ["user_id = ?", self.id]
  end

  
  ## private methods  
  


end