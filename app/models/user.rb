# = Schema Information
#
# Table name: *users*
#
#  id                      :integer(4)      not null, primary key
#  email                   :string(255)
#  is_confirmed            :boolean(1)      not null
#  openid                  :string(255)
#  url                     :string(255)     default(""), not null
#  settings                :text
#  is_disabled             :boolean(1)      not null
#  created_at              :datetime        not null
#  entries_count           :integer(4)      default(0), not null
#  updated_at              :datetime
#  is_anonymous            :boolean(1)      not null
#  is_mainpageable         :boolean(1)      not null
#  is_premium              :boolean(1)      not null
#  domain                  :string(255)
#  private_entries_count   :integer(4)      default(0), not null
#  email_comments          :boolean(1)      default(TRUE), not null
#  comments_auto_subscribe :boolean(1)      default(TRUE), not null
#  gender                  :string(1)       default("m"), not null
#  username                :string(255)
#  salt                    :string(40)
#  crypted_password        :string(40)
#  messages_count          :integer(4)      default(0), not null
#  faves_count             :integer(4)      default(0), not null
#  entries_updated_at      :datetime
########
class User < ActiveRecord::Base
  ## included modules & attr_*
  ## associations
	has_many      :entries, :dependent => :destroy
	has_one       :avatar, :dependent => :destroy
  has_one       :tlog_settings, :dependent => :destroy
  has_one       :tlog_design_settings, :dependent => :destroy
  has_one       :mobile_settings, :dependent => :destroy  
  has_many      :sidebar_sections, :dependent => :destroy
  has_many      :bookmarklets, :dependent => :destroy
  has_one       :feedback, :dependent => :destroy
  has_many      :messages, :dependent => :destroy
  has_many      :faves, :dependent => :destroy


  ## plugins
  concerned_with :authentication,
                  :relationships,
                  :settings,
                  :tags,
                  :confirmation,
                  :entries,
                  :permissions,
                  :calendar  
  


  ## named_scopes
  named_scope   :confirmed, :conditions => 'is_confirmed = 1'
  named_scope   :unconfirmed, :conditions => 'is_confirmed = 0'
  named_scope   :active, :conditions => 'is_disabled = 0'
  named_scope   :disabled, :conditions => 'is_disabled = 1'
  
  
  ## validations
  validates_format_of     :domain,
                          :with => Format::DOMAIN,
                          :on => :save,
                          :message => 'не похоже на домен',
                          :if => Proc.new { |u| !u.domain.blank? }


  ## callbacks
  after_destroy { |user| user.disconnect! }
  after_create do |user|
    user.tlog_settings = TlogSettings.create :user => user
    user.tlog_design_settings = TlogDesignSettings.create :user => user
    # добавляем новости автоматически
    news = User.find_by_url('news')
    Relationship.create(:user => news, :reader => user, :position => 0, :last_viewed_entries_count => news.entries_count_for(user), :last_viewed_at => Time.now, :friendship_status => Relationship::DEFAULT) if news
  end


  ## class methods
  ## public methods

  # Пример: <%= user.gender("он", "она") %>
  def gender(he = nil, she = nil)
    gender = read_attribute(:gender)
    (he && she) ? (gender.to_s == 'f' ? she : he) : gender
  end

  def username
    @username ||= read_attribute(:username).blank? ? self.url : read_attribute(:username)
  end      

  # блокируем пользователя
  def disable!
    return false if self.is_disabled?

    # выставляем флаг заблокированности
    self.is_disabled = true
    self.save
    
    # отключаем пользователя от друзей
    self.disconnect!
  
    # на данный моммент не удаляем, а скрываем все записи из прямого эфира
    self.entries.each do |entry|
      # публичные записи прячем
      if entry.is_mainpageable?
        entry.visibility = 'public' 
        entry.save
      end
      
      # а анонимки - удаляем
      entry.destroy if entry.is_anonymous?
    end
    
    # удаляем личную переписку, избранное и feedback, если был
    self.messages.map(&:destroy)
    self.faves.map(&:destroy)
    self.feedback.destroy unless self.feedback.blank?
  end
  
  # отключаем пользователя от друзей
  def disconnect!
    # удяляем relationships
    self.connection.delete("DELETE FROM relationships WHERE user_id = #{self.id} OR reader_id = #{self.id}")
    # удаляем все подписки
    self.connection.delete("DELETE FROM entry_subscribers WHERE user_id = #{self.id}")
  end

  
  ## private methods  


end
