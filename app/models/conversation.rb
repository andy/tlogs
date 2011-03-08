class Conversation < ActiveRecord::Base
  belongs_to :user, :counter_cache => true
  belongs_to :recipient, :class_name => 'User'
  has_many :messages, :dependent => :destroy

  belongs_to :last_message, :class_name => 'Message'
  
  named_scope :unreplied, :conditions => 'is_replied = 0'
  
  named_scope :unviewed, :conditions => 'is_viewed = 0'
  
  named_scope :with, lambda { |user| { :conditions => ['recipient_id = ?', user.id] } }


  before_create { |record| record.send_notifications = record.user.tlog_settings.email_messages }


  # shadow conversation — opposite conversation by other party
  def shadow
    Conversation.find_by_user_id_and_recipient_id(self.recipient_id, self.recipient_id)
  end
  
  def to_param
    recipient.url
  end
end
