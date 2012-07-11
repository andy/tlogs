# == Schema Information
# Schema version: 20120711194752
#
# Table name: conversations
#
#  id                   :integer(4)      not null, primary key
#  user_id              :integer(4)      not null, indexed => [recipient_id], indexed => [last_message_at], indexed => [is_replied], indexed => [is_viewed]
#  recipient_id         :integer(4)      not null, indexed => [user_id]
#  messages_count       :integer(4)      default(0), not null
#  send_notifications   :boolean(1)      default(TRUE), not null
#  is_replied           :boolean(1)      default(FALSE), not null, indexed => [user_id], indexed
#  is_viewed            :boolean(1)      default(FALSE), not null, indexed => [user_id], indexed
#  last_message_id      :integer(4)
#  last_message_user_id :integer(4)
#  last_message_at      :datetime        indexed => [user_id], indexed
#  created_at           :datetime
#  updated_at           :datetime
#  is_disabled          :boolean(1)      default(FALSE), not null, indexed
#
# Indexes
#
#  index_conversations_on_user_id_and_recipient_id     (user_id,recipient_id)
#  index_conversations_on_user_id_and_last_message_at  (user_id,last_message_at)
#  index_conversations_on_user_id_and_is_replied       (user_id,is_replied)
#  index_conversations_on_user_id_and_is_viewed        (user_id,is_viewed)
#  index_conversations_on_is_disabled                  (is_disabled)
#  index_conversations_on_last_message_at              (last_message_at)
#  index_conversations_on_is_viewed                    (is_viewed)
#  index_conversations_on_is_replied                   (is_replied)
#

class Conversation < ActiveRecord::Base
  belongs_to :user, :counter_cache => true
  belongs_to :recipient, :class_name => 'User'
  has_many :messages, :dependent => :destroy

  belongs_to :last_message, :class_name => 'Message'
  
  named_scope :unreplied, :conditions => 'is_replied = 0'
  
  named_scope :unviewed, :conditions => 'is_viewed = 0'
  
  named_scope :with, lambda { |user| { :conditions => ['recipient_id = ?', user.id] } }

  named_scope :active, :conditions => 'is_disabled = 0'
  
  named_scope :disabled, :conditions => 'is_disabled = 1'


  before_create do |record|
    record.send_notifications = record.user.tlog_settings.email_messages
    
    true
  end


  # shadow conversation — opposite conversation by other party
  def shadow
    Conversation.find_by_user_id_and_recipient_id(self.recipient_id, self.user_id)
  end
  
  def to_param
    recipient.url
  end
  
  
  def block!
    update_attributes!(:is_disabled => true) unless is_disabled?
  end
  
  def async_destroy!
    block!

    Resque.enqueue(ConversationDestroyJob, self.id)
  end
end
