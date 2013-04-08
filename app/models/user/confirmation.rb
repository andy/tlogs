class User
  ## included modules & attr_*
  EMAIL_SIGNATURE_SECRET = 'YO SHALL NOT KNOW EVER!@@@#!'

  ## associations
  ## plugins
  ## named_scopes
  ## validations
  ## callbacks
  ## class methods
  ## public methods
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

  ## private methods

end
