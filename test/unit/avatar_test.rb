# == Schema Information
# Schema version: 20110223155201
#
# Table name: avatars
#
#  id           :integer(4)      not null, primary key
#  user_id      :integer(4)      default(0), not null
#  content_type :string(255)
#  filename     :string(255)
#  size         :integer(4)
#  position     :integer(4)
#  parent_id    :integer(4)
#  thumbnail    :string(255)
#  width        :integer(4)
#  height       :integer(4)
#
# Indexes
#
#  index_avatars_on_user_id    (user_id)
#  index_avatars_on_parent_id  (parent_id)
#

require File.dirname(__FILE__) + '/../test_helper'

class AvatarTest < Test::Unit::TestCase
  fixtures :avatars

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
