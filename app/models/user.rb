# == Schema Information
# Schema version: 20110816190509
#
# Table name: users
#
#  id                      :integer(4)      not null, primary key
#  email                   :string(255)     indexed
#  is_confirmed            :boolean(1)      default(FALSE), not null, indexed, indexed => [entries_count]
#  openid                  :string(255)     indexed
#  url                     :string(255)     default(""), not null, indexed
#  settings                :text
#  is_disabled             :boolean(1)      default(FALSE), not null
#  created_at              :datetime        not null
#  entries_count           :integer(4)      default(0), not null, indexed, indexed => [is_confirmed]
#  updated_at              :datetime
#  is_anonymous            :boolean(1)      default(FALSE), not null
#  is_mainpageable         :boolean(1)      default(FALSE), not null
#  domain                  :string(255)     indexed
#  private_entries_count   :integer(4)      default(0), not null
#  email_comments          :boolean(1)      default(TRUE), not null
#  comments_auto_subscribe :boolean(1)      default(TRUE), not null
#  gender                  :string(1)       default("m"), not null
#  username                :string(255)
#  salt                    :string(40)
#  crypted_password        :string(40)
#  faves_count             :integer(4)      default(0), not null
#  entries_updated_at      :datetime
#  conversations_count     :integer(4)      default(0), not null
#  disabled_at             :datetime
#  ban_ac_till             :datetime
#  userpic_file_name       :string(255)
#  userpic_updated_at      :datetime
#  userpic_meta            :text
#  premium_till            :datetime
#
# Indexes
#
#  index_users_on_email                           (email)
#  index_users_on_openid                          (openid)
#  index_users_on_url                             (url)
#  index_users_on_domain                          (domain)
#  index_users_on_is_confirmed                    (is_confirmed)
#  index_users_on_entries_count                   (entries_count)
#  index_users_on_is_confirmed_and_entries_count  (is_confirmed,entries_count)
#

class User < ActiveRecord::Base
  ## included modules & attr_*
  ## associations
	has_many      :entries, :dependent => :destroy
	has_many      :anonymous_entries, :class_name => 'AnonymousEntry'
	has_one       :avatar, :dependent => :destroy
  has_one       :tlog_settings, :dependent => :destroy
  has_one       :tlog_design_settings, :dependent => :destroy
  has_one       :mobile_settings, :dependent => :destroy  
  has_many      :sidebar_sections, :dependent => :destroy
  has_many      :bookmarklets, :dependent => :destroy
  has_one       :feedback, :dependent => :destroy
  has_many      :conversations, :dependent => :destroy, :order => 'last_message_at DESC'
  has_many      :shade_conversations, :class_name => 'Conversation', :dependent => :destroy, :order => 'last_message_at DESC', :foreign_key => 'recipient_id'
  has_many      :faves, :dependent => :destroy
  has_many      :invoices
  has_many      :backgrounds, :dependent => :destroy
  

  ## plugins
  concerned_with :authentication,
                  :relationships,
                  :settings,
                  :tags,
                  :confirmation,
                  :entries,
                  :permissions,
                  :calendar,
                  :entries_queue,
                  :ban
  
	define_index do
    indexes :url
    indexes :username
    
    has :entries_count
    has :created_at
    has :updated_at
    has :is_disabled
    has :is_confirmed
    
    where 'users.is_disabled = 0 AND users.is_confirmed = 1'
  end
  
  has_attached_file :userpic,
    :url    => '/assets/userpic/:sha1_partition/:id_:style.:extension',
    :path   => ':rails_root/public:url',
    :use_timestamp => false,
    :convert_options => { :all => '-strip' },
    :styles => {
      :large    => '800x800>',
      :thumb128 => '128x128>',
      :thumb64  => '64x64>',
      :thumb32  => '32x32>',
      :thumb16  => '16x16>',
      :touch    => ['114x114#', :png]
    },
    :default_style => :thumb64
  
  # validates_attachment_size :userpic, :less_than => 5.megabytes
  # validates_attachment_content_type :userpic, :content_type => ['image/jpeg', 'image/png', 'image/gif']


  ## named_scopes
  named_scope   :confirmed, :conditions => 'is_confirmed = 1'
  named_scope   :unconfirmed, :conditions => 'is_confirmed = 0'
  named_scope   :active, :conditions => 'is_disabled = 0'
  named_scope   :disabled, :conditions => 'is_disabled = 1'
  named_scope   :expired, :conditions => 'is_disabled = 1 AND disabled_at < DATE_SUB(CURDATE(), INTERVAL 1 MONTH)'
  named_scope   :premium, :conditions => 'premium_till IS NOT NULL AND premium_till > CURDATE()'

  
  ## validations
  validates_format_of     :domain,
                          :with => Format::DOMAIN,
                          :on => :save,
                          :message => 'не похоже на домен',
                          :if => Proc.new { |u| !u.domain.blank? }


  ## callbacks
  before_destroy { |user| user.disable! }

  after_create do |user|
    # set female as default gender
    user.gender = 'f'
    
    # allow being mainpageable
    user.is_mainpageable = true
    
    # initialize empty global & design settings
    user.tlog_settings        = TlogSettings.create :user => user, :comments_enabled => true
    user.tlog_design_settings = TlogDesignSettings.create :user => user

    # subscribe to 'news' user
    news = User.find_by_url('news')
    Relationship.create(:user => news, :reader => user, :position => 0, :last_viewed_entries_count => news.entries_count_for(user), :last_viewed_at => Time.now, :friendship_status => Relationship::DEFAULT) if news
  end


  ## class methods
  def self.active_for(user, options = {})
    options.reverse_merge!(:limit => 6, :popularity => 2)
    
    user_ids = Rails.cache.fetch("users::active", :expires_in => 10.minutes) do
      Relationship.find(:all, :select => 'user_id', :order => 'id desc', :limit => 1000).map(&:user_id)
    end
    
    user_ids =  user_ids.sort.                        # sort numerically
                group_by { |x| x }.                   # group the same accounts together
                sort_by { |k, v| v.length }.          # sort by popularity
                select { |k, v| v.length >= options[:popularity] }.  # but select only people who have at least more active subscribers
                map(&:first).                         # keep only ids
                reverse

    User.find_all_by_id(user_ids.sort_by({ rand })[0...(options[:limit] * 2)], :include => [:avatar, :tlog_settings]).select { |u| u.can_be_viewed_by?(user) }[0..options[:limit]]
  end

  
  ## public methods

  # Пример: <%= user.gender("он", "она") %>
  def gender(he = nil, she = nil)
    gender = read_attribute(:gender)
    (he && she) ? (gender.to_s == 'f' ? she : he) : gender
  end

  def username
    @username ||= read_attribute(:username).blank? ? self.url : read_attribute(:username)
  end
  
  def unreplied_conversations_count
    @unrepied_conversations_count ||= self.conversations.active.unreplied.count
  end
  
  def unviewed_conversations_count
    @unviewed_conversations_count ||= self.conversations.active.unviewed.count
  end

  # blocks access to tlog
  def block!
    unless self.is_disabled?
      self.is_disabled = true
      self.is_mainpageable = false
      self.save!

      self.touch(:disabled_at)
    end
  end

  # блокируем пользователя
  # в основном удаляются вещи которые попадают или могут попадать в ленты других пользователей
  # или как-то влиять на общий флоу в сервисе
  def disable!
    block!

    # на данный моммент не удаляем, а скрываем все записи из прямого эфира
    self.entries.paginated_each { |entry| entry.disable! }
    
    # анонимки - удаляем
    Entry.destroy(self.anonymous_entry_ids)

    # отключаем пользователя от друзей
    self.disconnect!(true)

    # destroy faves
    self.faves.map(&:destroy)
    
    # destroy feedback if he had one
    self.feedback.destroy unless self.feedback.blank?
  end

  # asynchronously delete tlog
  def async_disable!
    block!

    Resque.enqueue(TlogDisableJob, self.id)
  end
  
  # asynchronously destroy tlog
  def async_destroy!
    block!
    
    Resque.enqueue(TlogDestroyJob, self.id)
  end
  
  def rename!
    self.remove_subscribers!

    self.conversations.map(&:destroy)

    self.shade_conversations.map(&:destroy)    
  end
  
  # отключаем друзей от пользователя
  # full - так же отключаем пользователя от друзей
  def disconnect!(full = false)
    # delete both sides of conversations
    self.conversations.map(&:destroy)
    self.shade_conversations.map(&:destroy)

    # удаляем все комменатрии — по ним можно найти
    # TO DO
    
    # удяляем relationships
    self.connection.delete("DELETE FROM relationships WHERE user_id = #{self.id} OR reader_id = #{self.id}")
    # удаляем все подписки
    self.connection.delete("DELETE FROM entry_subscribers WHERE user_id = #{self.id}")
  end
  
  def destroy_code
    Digest::SHA1.hexdigest("#{self.email}--#{self.url}--#{self.entries_updated_at}")
  end

  ## private methods
end
