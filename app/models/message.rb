# == Schema Information
# Schema version: 20120711194752
#
# Table name: messages
#
#  id              :integer(4)      not null, primary key
#  user_id         :integer(4)      default(0), not null, indexed
#  body            :text            default(""), not null
#  created_at      :datetime        not null
#  updated_at      :datetime
#  conversation_id :integer(4)      not null, indexed
#  recipient_id    :integer(4)      not null
#
# Indexes
#
#  index_messages_on_user_id          (user_id)
#  index_messages_on_conversation_id  (conversation_id)
#

class Message < ActiveRecord::Base
  belongs_to :user # пользователь создавший сообщение
  belongs_to :recipient, :class_name => 'User' # пользователь получивший его
  belongs_to :conversation, :counter_cache => true

  ## validations
  # validates_presence_of :conversation
  validates_presence_of :recipient
  validates_presence_of :user
  validates_length_of :body, :in => 2..4086, :allow_nil => false, :allow_blank => false, :too_short => 'уж напишите что-нибудь, пожалуйста', :too_long => 'слишком длинное сообщение получилось, не можем отправить'
  validate :must_not_be_blacklisted

  ## attributes
  attr_accessor :recipient_url

  attr_accessible :body, :recipient_url

  ## plugins
  define_index do
    indexes :body

    has conversation(:user_id), :as => :conversation_user_id
    has conversation(:recipient_id), :as => :conversation_recipient_id
    has conversation(:is_replied), :as => :conversation_is_replied
    has conversation(:is_viewed), :as => :conversation_is_viewed
    has conversation(:is_disabled), :as => :conversation_is_disabled
    has user_id, recipient_id, created_at, updated_at

    group_by "conversation_user_id"
    group_by "conversation_recipient_id"
  
    where "conversations.is_disabled = 0"
  
    set_property :delta => :datetime, :threshold => 1.hour
  end

  ## hooks
  # update conversations field to the last message changed
  after_save do |record|
    record.mark_as_last_message!

    true
  end

  # update conversations field if that's current last message there
  after_destroy do |message|
    convo = message.conversation

    if convo
      convo.update_attributes!(:last_message_id => nil) if convo.last_message_id == message.id

      # <= 1 because counters are decremented after after_destroy
      convo.destroy if convo.messages_count <= 1
    end

    true
  end

  ## public methods
  #
  def mark_as_last_message!
    convo = self.conversation

    # if tthat's a reply from convo owner perspective (e.g. message does not belong to him)
    # OR special case where you message yourself ...
    if self.user_id != convo.user_id || convo.user_id == convo.recipient_id
      convo.update_attributes!(:last_message_id => self.id, :last_message_user_id => self.user_id, :last_message_at => self.created_at, :is_replied => false)
    else
      # if that is your reply — just update the is_replied flag to true
      convo.is_replied = true

      # mark as viewed if you just have replied
      # convo.is_viewed = false

      # update timestamp only on first message, other replies should keep things AS IS
      convo.last_message_at = self.created_at if convo.last_message_at.nil?
      convo.save!
    end
  end

  # initiates or updates curerntly ongoing conversation
  # returns recipient message
  def begin_conversation!(options = {})
    options.assert_valid_keys(:send_notifications)

    result = nil

    ActiveRecord::Base.transaction do
      convo = Conversation.find_or_create_by_user_id_and_recipient_id(self.user_id, self.recipient_id)
      convo.update_attributes!(:send_notifications => options[:send_notifications]) if options[:send_notifications]
      convo.messages << self

      shade = nil

      # post that on shadow conversation only if that's a different userid
      if self.recipient_id != self.user_id
        shade = Conversation.find_or_create_by_user_id_and_recipient_id(self.recipient_id, self.user_id)
        shade.toggle!(:is_viewed) if shade.is_viewed?
        shade.messages << self.clone
      end

      # find the last message and do this in current transaction
      result = shade ? shade.messages.last : convo.messages.last
    end

    result
  end

  # only conversation owner can remove message
  def can_be_deleted_by?(user)
    self.conversation.user_id == user.id
  end

  # wether email notification should be delivered to recipient of this message
  # be careful, as this must be called on message to be delivered, not shadow message!
  def should_be_delivered?
    # if that's me is mailing me
    return false if self.user_id == self.recipient_id

    # if recipient is not emailable at all
    return false unless self.recipient.is_emailable?

    # if recipient turned off all messages notifications, don't mail either
    return false unless self.recipient.tlog_settings.email_messages?

    # wether this conversation has notifications turned off
    return false unless self.conversation.shadow.send_notifications?

    true
  end

  # Emailer.deliver_message(current_service, @message.recipient, @recipient_message) if @recipient_message.should_be_delivered?
  def deliver!(current_service)
    Emailer.deliver_message(current_service, self.recipient, self) if self.should_be_delivered?
  end

  def async_deliver!(current_service)
    Resque.enqueue(MessageDeliverJob, self.id, current_service.domain) if self.should_be_delivered?
  end

  protected
    def must_not_be_blacklisted
      errors.add :body, 'Вы не можете отправлять этому пользователю сообщения' if self.recipient &&  (self.user.is_blacklisted_for?(self.recipient) || self.recipient.is_blacklisted_for?(self.user))
    end
end
