# encoding: utf-8
# == Schema Information
# Schema version: 20110816190509
#
# Table name: conversations
#
#  id                   :integer(4)      not null, primary key
#  user_id              :integer(4)      not null, indexed => [recipient_id], indexed => [last_message_at]
#  recipient_id         :integer(4)      not null, indexed => [user_id]
#  messages_count       :integer(4)      default(0), not null
#  send_notifications   :boolean(1)      default(TRUE), not null
#  is_replied           :boolean(1)      default(FALSE), not null, indexed
#  is_viewed            :boolean(1)      default(FALSE), not null, indexed
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

  def self.with user
    where(:recipient_id => user.id)
  end
  scope :unreplied, where(:is_replied => false)
  scope :unviewed, where(:is_viewed => false)
  scope :active, where(:is_disabled => false)
  scope :disabled, where(:is_disabled => true)


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
