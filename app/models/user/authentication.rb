class User
  RESERVED = %w( mmm-tasty mobile rest blog blogs www support help ftp http ed2k smtp pop pop3 adm mail admin test password restore backup sys system dev account register signup web wwww ww w mmm info ad archive status logs log guest debug demo podcast info tools guide preview svn example google yandex rambler goog googl goggle gugl assets assets0 assets1 assets2 assets3 asset asset0 asset1 asset2 asset3 asset4 )
  SIGNATURE_SECRET = 'kab00mmm, tasty!'
  EMAIL_SIGNATURE_SECRET = 'YO SHALL NOT KNOW EVER!@@@#!'

  attr_accessor :password
  attr_accessible :openid, :email, :url, :password

	validates_presence_of :url, :on => :save, :message => "это обязательное поле"
	validates_uniqueness_of :email, :if => Proc.new { |u| !u.email.blank? }, :message => 'пользователь с таким емейлом уже зарегистрирован', :case_sensitive => false
	validates_uniqueness_of :openid, :if => Proc.new { |u| !u.openid.blank? }, :message => 'пользователь с таким openid уже зарегистрирован', :case_sensitive => false
	validates_uniqueness_of :url, :message => 'к сожалению, этот адрес уже занят', :case_sensitive => false

	validates_format_of :openid, :with => Format::HTTP_LINK, :if => Proc.new { |u| !u.openid.blank? }, :message => 'не похоже на openid'
  validates_format_of :email, :with => Format::EMAIL, :if => Proc.new { |u| !u.email.blank? }, :message => 'не похоже на емейл или openid'
  validates_length_of :url, :within => 1..20, :too_long => 'адрес не может быть более 20и символов'
  validates_format_of :url, :with => /^[a-z0-9]([a-z0-9\-]{1,20})?$/i, :message => 'адрес содержит недопустимые символы. пожалуйста, выберите другой'
  validates_exclusion_of :url, :in => RESERVED, :message => 'к сожалению, этот адрес уже занят'

  validates_length_of :password, :within => 5..20, :if => Proc.new { |u| !u.password.blank? }, :too_short => 'пароль слишком короткий, минимум 5 символов'
  
  before_save :encrypt_password
	
  def validate
    if openid.blank? && email.blank?
      errors.add(:email, 'укажите, пожалуйста, адрес')
    end
    
    if openid.blank? && !email.blank? && password.nil? && crypted_password.blank?
      errors.add(:password, 'необходимо выбрать пароль')
    end    
  end
	
  def signature
    Digest::SHA1.digest([self.id, self.is_openid? ? self.openid : self.email, self.created_at.to_s, SIGNATURE_SECRET].pack('LZ*Z*Z*'))
  end
  
  def recover_secret
    Digest::SHA1.hexdigest([self.id, self.email, self.crypted_password, self.created_at.to_s, SIGNATURE_SECRET].pack('LZ*Z*Z*Z*'))
  end
  
  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
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
  
  def is_openid?
    !self.openid.blank?
  end
  
  def confirmation_code_for(email)
    Digest::SHA1.hexdigest("- #{email} - #{EMAIL_SIGNATURE_SECRET} -")[0..8]
  end

  def update_confirmation!(email=nil)
    email ||= self.email
    self.settings_will_change!
    self.settings[:email_confirmation_code] = [ email, self.confirmation_code_for(email) ]
    self.update_attribute(:settings, self.settings) unless self.new_record?
  end
  
  def read_confirmation_code
    "#{self.id}_#{self.settings[:email_confirmation_code][1]}"
  end
  
  def read_confirmation_email
    self.settings[:email_confirmation_code][0] rescue nil
  end
  
  def clear_confirmation
    self.settings_will_change!
    self.settings.delete(:email_confirmation_code)
  end

  # возвращает либо новый емейл, либо nil
  def validate_confirmation(code)
    code = code.split(/_/)[1] if code =~ /^\d+_[a-f0-9]{7,33}$/i # убираем префикс с ID
    valid_email, valid_code = self.settings[:email_confirmation_code]
    return valid_email if valid_code == code
    # всегда проверяем основной емейл
    return self.email if !self.email.blank? && self.confirmation_code_for(self.email) == code
    nil
  end
  
  
  private
    # before filter 
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{url}--")
      self.crypted_password = encrypt(password)
    end  
end