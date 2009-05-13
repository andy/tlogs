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
  
  # пользователь выключен, анонимен, либо имеет неподтвержденный емейл адрес
  def is_limited?
    self.is_disabled? || (!self.is_openid? && !self.is_confirmed?)
  end
  
  # можно ли пользователю отправлять письма?
  def is_emailable?
    self.is_confirmed? && !self.email.blank? && !self.is_disabled?
  end

  def can_create?(klass)
    return true if self.is_premium?
    if klass.to_s == 'SongEntry'
      return false if klass.count(:conditions => "user_id = #{self.id} AND created_at > CURDATE()") > 0 # не более одной в день
    end
    true
  end
  
  # может ли вообще голосовать за эту запись?
  def can_vote?(entry)
    return false if self.is_limited?
    return false if entry.user_id == self.id
    true
  end
  
  # сила голоса пользователя. Пока что абсолютно равоне для всех
  def vote_power
    1
  end


  ## private methods  
  
  
end