# == Schema Information
#
# Table name: transactions
#
#  id         :integer(4)      not null, primary key
#  user_id    :integer(4)      not null
#  amount     :integer(4)      not null
#  state      :string(255)     default("pending"), not null
#  created_at :datetime
#  updated_at :datetime
#

require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
