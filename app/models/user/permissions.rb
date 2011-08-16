class User
  ## included modules & attr_*
  ## associations
  ## plugins
  ## named_scopes
  ## validations
  ## callbacks
  ## class methods
  ## public methods
  
  def self.admins
    [1, 2]
  end

  def is_admin?
    [1, 2].include?(self.id)
  end
  
  # moderators (admins + no one yet)
  def is_moderator?
    is_admin?
  end
  
  # пользователь выключен, анонимен, либо имеет неподтвержденный емейл адрес
  def is_limited?
    self.is_disabled? || (!self.is_openid? && !self.is_confirmed?)
  end
  
  # можно ли пользователю отправлять письма?
  def is_emailable?
    self.is_confirmed? && !self.email.blank? && !self.is_disabled?
  end
  
  # checks wether this tlog can be viewed by other users
  def can_be_viewed_by?(user)
    # you can always view your own tlog
    return true if user && user.id == self.id
    
    case self.tlog_settings.privacy
    when 'open'
      true
      
      # registration required
    when 'rr'
      user ? true : false
      
      # friend-mode
    when 'fr'
      user && self.all_friend_ids.include?(user.id)
      
      # only me
    when 'me'
      user && user.id == self.id
    end
  end
  
  def visibility_limit
    # limits
    limits = {}

    # on 27 apr 2011 registration was open, limit those people forever
    if self.created_at > "27 apr 2011".to_time
      limits = {
        (0...4.weeks) => { :mainpageable_entries => 3, :voteable_entries => 1 },
        (4.weeks..100.years) => { :mainpageable_entries => 6, :voteable_entries => 2 }
      }
    else
      limits = {
        (0..3.weeks) => { :mainpageable_entries => 3, :voteable_entries => 1 },
        (3.weeks...4.weeks) => { :mainpageable_entries => 6, :voteable_entries => 2 },
        (4.weeks...100.years) => { :mainpageable_entries => nil, :voteable_entries => nil }
      }
    end    

    age   = Time.now - self.created_at
    limit = limits.find { |l| l[0].include?(age) }[1]
  end
  
  def allowed_visibilities
    allow  = Entry::VISIBILITY.keys
    reject = []
    
    # premium users are unlimited
    # return allow if self.is_premium?

    entries = self.entries.find(:all, :select => 'entries.id, entries.is_voteable, entries.is_mainpageable', :conditions => 'entries.is_mainpageable = 1 AND entries.created_at > DATE_SUB(NOW(), INTERVAL 24 HOUR)')
    
    mainpageable_entries = entries.select { |e| e.is_mainpageable? }.length
    voteable_entries     = entries.select { |e| e.is_voteable? }.length
    
    limit = self.visibility_limit

    reject << [:mainpageable, :voteable] if limit[:mainpageable_entries] && mainpageable_entries >= limit[:mainpageable_entries]
    reject << :voteable if limit[:voteable_entries] && voteable_entries >= limit[:voteable_entries]

    allow - reject.flatten
  end

  def is_allowed_visibility?(value)
    self.allowed_visibilities.include?(value.to_sym) ? true : false
  end

  # возвращает причину по которой нельзя создавать запись (Reason), либо nil если запись можно создавать
  def can_create?(klass)
    reason = nil

    case klass.to_s
      when 'SongEntry'
        # не более одной в день
        # if klass.count(:conditions => "user_id = #{self.id} AND created_at > CURDATE()") > 0
        #   reason = Reason.new "К сожалению, музыку можно заливать лишь раз в день."
        #   reason.expires_at = Time.now.tomorrow.midnight
        # end
        
        reason = Reason.new "К сожалению, мы временно отключили возможность заливать музыку прямо на тейсти :( Поэтому, как временное решение, пользуйтесь сервисами на которые можно залить треки, а потом вставляйте проигрыватель в тейсти. Приносим свои извинения за неудобства."

      when 'AnonymousEntry'
        # анонимки можно создавать только раз в неделю
        # logger.debug "self = #{self.inspect}"
        # logger.debug "klass = #{klass.inspect}"

        entry = Entry.anonymous.for_user(self).last
        if entry
          if entry.is_disabled?
            if entry.created_at > 2.month.ago
              reason = Reason.new "Ваша последняя анонимка была удалена меньше месяца назад."
              reason.expires_at = entry.created_at + 2.month
            end
          elsif entry.created_at > 2.weeks.ago
            reason = Reason.new "Анонимки можно писать не чаще раза в две недели."
            reason.expires_at = entry.created_at + 2.weeks
          end
        # и только спустя месяц после регистрации
        elsif self.created_at > 6.months.ago
          reason = Reason.new "Анонимки можно писать только спустя шесть месяцев после регистрации."
          reason.expires_at = self.created_at + 6.months
        end

    end # unless self.is_premium?
    
    reason
  end
  
  # может ли вообще голосовать за эту запись?
  def can_vote?(entry)
    return false if self.is_limited?
    return false if entry.user_id == self.id
    true
  end
  
  # сила голоса пользователя. Пока что абсолютно равное значение для всех
  def vote_power
    1
  end

  # показывать ли пользователю бета-функции
  def in_beta?
    !!self.relationship_with(User.find_by_url('beta'))
  end
  
  def is_premium?
    self.premium_till && self.premium_till > Time.now
  end

  ## private methods  
  
  
end