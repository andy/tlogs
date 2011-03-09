# == Schema Information
# Schema version: 20110223155201
#
# Table name: comments
#
#  id           :integer(4)      not null, primary key
#  entry_id     :integer(4)      default(0), not null
#  comment      :text
#  user_id      :integer(4)      not null
#  is_disabled  :boolean(1)      default(FALSE), not null
#  created_at   :datetime        not null
#  updated_at   :datetime
#  comment_html :text
#  remote_ip    :string(17)
#
# Indexes
#
#  index_comments_on_entry_id    (entry_id)
#  index_comments_on_user_id     (user_id)
#  index_comments_on_created_at  (created_at)
#

require File.dirname(__FILE__) + '/../test_helper'

class CommentTest < Test::Unit::TestCase
  fixtures :comments

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
