# == Schema Information
# Schema version: 20110223155201
#
# Table name: conversations
#
#  id                   :integer(4)      not null, primary key
#  user_id              :integer(4)      not null
#  recipient_id         :integer(4)      not null
#  messages_count       :integer(4)      default(0), not null
#  send_notifications   :boolean(1)      default(TRUE), not null
#  is_replied           :boolean(1)      default(FALSE), not null
#  is_viewed            :boolean(1)      default(FALSE), not null
#  last_message_id      :integer(4)
#  last_message_user_id :integer(4)
#  last_message_at      :datetime
#  created_at           :datetime
#  updated_at           :datetime
#
# Indexes
#
#  index_conversations_on_user_id_and_recipient_id     (user_id,recipient_id)
#  index_conversations_on_user_id_and_last_message_at  (user_id,last_message_at)
#

require 'test_helper'

class ConversationTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
