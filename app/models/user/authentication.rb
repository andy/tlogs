class User
  ## included modules & attr_*
  RESERVED = %w( mmm-tasty mobile rest blog blogs www support help ftp http ed2k smtp pop pop3 adm mail admin test password restore backup sys system dev account register signup web wwww ww w mmm info ad archive status logs log guest debug demo podcast info tools guide preview svn example google yandex rambler goog googl goggle gugl assets assets0 assets1 assets2 assets3 asset asset0 asset1 asset2 asset3 asset4 unreplied unread mail verify_recipient resque tumblr viewy m )
  SIGNATURE_SECRET = 'kab00mmm, tasty!'

  attr_accessor :password
  attr_accessor :eula
  attr_accessible :openid, :email, :url, :password, :eula


  ## associations
  ## plugins
  ## named_scopes
  ## validations
  validates_acceptance_of     :eula,
                              :on => :create,
                              :message => "вы должны принять и прочесть пользовательское соглашение"

	validates_presence_of       :url,
	                            :message => "это обязательное поле"

	validates_uniqueness_of     :url,
	                            :message => 'к сожалению, этот адрес уже занят',
	                            :case_sensitive => false

  validates_length_of         :url,
                              :within => 1..20,
                              :too_long => 'адрес не может быть более 20и символов'

  validates_format_of         :url,
                              :with => /^[a-z0-9]([a-z0-9\-]{1,20})?$/i,
                              :message => 'адрес содержит недопустимые символы. пожалуйста, выберите другой'

  validates_exclusion_of      :url,
                              :in => RESERVED,
                              :message => 'к сожалению, этот адрес уже занят'


	validates_uniqueness_of     :email,
	                            :if => Proc.new { |u| !u.email.blank? },
	                            :message => 'пользователь с таким емейлом уже зарегистрирован',
	                            :on => :create,
	                            :case_sensitive => false

  validates_format_of         :email,
                              :with => Format::EMAIL,
                              :message => 'не похоже на емейл или openid',
                              :if => Proc.new { |u| !u.email.blank? }


	validates_uniqueness_of     :openid,
                            	:message => 'пользователь с таким openid уже зарегистрирован',
	                            :case_sensitive => false,
	                            :if => Proc.new { |u| !u.openid.blank? }

	validates_format_of         :openid,
	                            :with => Format::HTTP_LINK,
	                            :message => 'не похоже на openid',
	                            :if => Proc.new { |u| !u.openid.blank? }


  validates_length_of         :password,
                              :within => 5..20,
                              :if => Proc.new { |u| !u.password.blank? },
                              :too_short => 'пароль слишком короткий, минимум 5 символов'


  def validate
    if openid.blank? && email.blank?
      errors.add(:email, 'укажите, пожалуйста, адрес')
    end
    
    if openid.blank? && !email.blank? && password.nil? && crypted_password.blank?
      errors.add(:password, 'необходимо выбрать пароль')
    end
    
    if !url.blank? && User::RESERVED.include?(url.downcase)
      errors.add(:url, 'к сожалению, этот адрес уже занят')
    end
  end  


  ## callbacks
  before_save :encrypt_password


  ## class methods
  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end
	
	# при авторизации по паролю нужно использовать эту функцию, потому
	#  что позже может быть добавлен механизм криптования паролей
	def self.authenticate(email, password)
	  return nil if email.empty?
	  user = User.find_by_email(email) || User.find_by_openid(email)
	  
	  # если пользователь не был найден по openid, попробуем добавить или убрать слеш в конце
	  #  http://anonuzer.myopenid.com -> http://anonuzer.myopenid.com/
	  if user.nil? && email.is_openid?
	    user = User.find_by_openid(email.ends_with?('/') ? email.chop : email + '/')
	  end

    # пользователь должен существовать и не должен быть заблокирован
	  return nil if user.nil? or user.is_disabled?
	  
	  # он может быть либо openid и тогда пароль не проверяется, либо обычным, но тогда
	  #  мы требуем чтобы пароль совпадал
	  return user if user.is_openid? || (user.crypted_password == encrypt(password, user.salt) && !user.crypted_password.blank?)
	  
	  # иначе - до свидания
	  nil
  end


  ## public methods
	def is_openid?
    !self.openid.blank?
  end
  
  def signature
    Digest::SHA1.digest([self.id, self.is_openid? ? self.openid : self.email, self.created_at.to_s, SIGNATURE_SECRET].pack('LZ*Z*Z*'))
  end
  
  def recover_secret
    Digest::SHA1.hexdigest([self.id, self.email, self.crypted_password, self.created_at.to_s, SIGNATURE_SECRET].pack('LZ*Z*Z*Z*'))
  end
  
  def encrypt(password)
    self.class.encrypt(password, salt)
  end
  
  def valid_password?(password)
    self.encrypt(password) == self.crypted_password
  end
  
  def link_key
    :ln
  end
  
  def linked_with
    self.settings[self.link_key] || []
  end
  
  def linked_accounts
    User.find(self.linked_with)
  end
  
  def link_with(link_user)
    links = self.linked_with + link_user.linked_with + [self.id, link_user.id]
    links.uniq!
    
    User.transaction do
      User.find(links).each do |user|
        user.settings_will_change!
        user.settings[self.link_key] = links
        user.save!

        Rails.logger.debug "* user #{user.id} chain of command is #{user.linked_with.join(', ')}"
      end
    end
  end
  
  def unlink_from(unlink_user)
    links = self.linked_with
    return unless links.include?(unlink_user.id)

    User.transaction do
      User.find(links).each do |user|
        user.settings_will_change!
        if user.id == unlink_user.id || user.linked_with.length <= 2
          user.settings.delete(user.link_key)
        else
          user.settings[user.link_key] = links - [unlink_user.id]
        end        
        user.save!
        
        Rails.logger.debug "* user #{user.id} chain of command is #{user.linked_with.join(', ')}"
      end
    end
  end
  
  def can_switch?
    Rails.cache.fetch("u:#{self.id}:#{self.linked_with.join('.')}:can_switch?", :expires_in => 1.day) do
      !!User.find(self.linked_with).find(&:is_premium?)
    end
  end

  def can_be_switched_to?(user)
    self.linked_with.include?(user.id) && self.can_switch?
  end
  

  ## private methods

  private
    # before filter 
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{url}--")
      self.crypted_password = encrypt(password)
    end  
end