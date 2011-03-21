class User
  ## included modules & attr_*
  ## associations
  ## plugins
  ## named_scopes
  ## validations
  ## callbacks
  ## class methods
  ## public methods

  def is_admin?
    [1, 2].include?(self.id)
  end
  
  # moderators (admins + astramak)
  def is_moderator?
    is_admin? || [9471].include?(self.id)
  end
  
  # пользователь выключен, анонимен, либо имеет неподтвержденный емейл адрес
  def is_limited?
    self.is_disabled? || (!self.is_openid? && !self.is_confirmed?)
  end
  
  # можно ли пользователю отправлять письма?
  def is_emailable?
    self.is_confirmed? && !self.email.blank? && !self.is_disabled?
  end
  
  def allowed_visibilities
    allow  = Entry::VISIBILITY.keys
    reject = []
    
    # premium users are unlimited
    return allow if self.is_premium?

    entries = self.entries.find(:all, :select => 'entries.id, entries.is_voteable, entries.is_mainpageable', :conditions => 'entries.is_mainpageable = 1 AND entries.created_at > DATE_SUB(NOW(), INTERVAL 24 HOUR)')
    
    mainpageable_entries = entries.select { |e| e.is_mainpageable? }.length
    voteable_entries     = entries.select { |e| e.is_voteable? }.length

    reject << [:mainpageable, :voteable] if mainpageable_entries >= 3
    reject << :voteable if voteable_entries >= 1

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
            if entry.created_at > 1.month.ago
              reason = Reason.new "Ваша последняя анонимка была удалена меньше месяца назад."
              reason.expires_at = entry.created_at + 1.month
            end
          elsif entry.created_at > 1.week.ago
            reason = Reason.new "Анонимки можно писать не чаще раза в неделю."
            reason.expires_at = entry.created_at + 1.week
          end
        # и только спустя месяц после регистрации
        elsif self.created_at > 1.month.ago
          reason = Reason.new "Анонимки можно писать только спустя месяц после регистрации."
          reason.expires_at = self.created_at + 1.month
        end

    end unless self.is_premium?
    
    reason
  end
  
  # может ли вообще голосовать за эту запись?
  def can_vote?(entry)
    return false if self.is_limited?
    return false if entry.user_id == self.id
    true
  end
  
  # сила голоса пользователя. Пока что абсолютно равне для всех
  def vote_power
    1
  end


  ## private methods  
  
  
end