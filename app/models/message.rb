# = Schema Information
#
# Table name: *messages*
#
#  id          :integer(4)      not null, primary key
#  user_id     :integer(4)      default(0), not null
#  sender_id   :integer(4)      default(0), not null
#  body        :text            default(""), not null
#  body_html   :text
#  is_private  :boolean(1)      not null
#  is_disabled :boolean(1)      not null
#  created_at  :datetime        not null
#  updated_at  :datetime
########
class Message < ActiveRecord::Base
  belongs_to :user # пользователь создавший сообщение
  belongs_to :recipient, :class_name => 'User' # пользователь получивший его
  belongs_to :conversation, :counter_cache => true

  ## validations
  # validates_presence_of :conversation
  validates_presence_of :recipient
  validates_presence_of :user
  validates_length_of :body, :in => 2..4086, :allow_nil => false, :allow_blank => false, :too_short => 'уж напишите что-нибудь, пожалуйста', :too_long => 'слишком длинное сообщение получилось, не можем отправить'

  ## attributes
  attr_accessor :recipient_url
  
  attr_accessible :body, :recipient_url

  ## plugins
	define_index do
	  indexes :body

	  has conversation(:user_id), :as => :conversation_user_id
	  has conversation(:recipient_id), :as => :conversation_recipient_id
    has user_id, recipient_id, created_at, updated_at

	  group_by "conversation_user_id"	  
	  group_by "conversation_recipient_id"
	  
	  set_property :delta => :datetime, :threshold => 1.hour
  end

  ## hooks
  # update conversations field to the last message changed
  after_save do |record|
    convo = record.conversation
    
    # if tthat's a reply from convo owner perspective (e.g. message does not belong to him)
    # OR special case where you message yourself ...
    if record.user_id != convo.user_id || convo.user_id == convo.recipient_id
      convo.update_attributes!(:last_message_id => record.id, :last_message_user_id => record.user_id, :last_message_at => record.created_at, :is_replied => false)
    else
      # if that is your reply — just update the is_replied flag to true
      convo.update_attributes!(:is_replied => true, :last_message_at => record.created_at)
    end
    
    true
  end
  
  # update conversations field if that's current last message there
  after_destroy do |message|
    convo = message.conversation(true)
    
    if convo.last_message_id == message.id
      if convo.messages_count.zero?
        # if this is last message, destroy the conversation too
        convo.destroy
      else
        convo.messages.last.save!
      end
    end
    
    true
  end

  ## public methods
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
    
    # wether this conversation has notifications turned off
    return false unless self.conversation.send_notifications?
    
    true
  end
end
