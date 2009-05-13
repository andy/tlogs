class User
	serialize :settings
	before_create :set_default_settings

  # выставляем пользователю ключ (и создаем новый если его не было еще)
  def last_personalized_key
    self.settings[:last_personalized_key] ||= begin
      key = String.random
      self.settings_will_change!
      self.settings[:last_personalized_key] = key
      self.save
      key
    end
  end

  private  
    def set_default_settings
      begin
  	    self.settings ||= Hash.new
  	  rescue ActiveRecord::SerializationTypeMismatch
  	    self.settings = Hash.new
      end
  	  true
    end
end