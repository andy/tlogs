# == Schema Information
# Schema version: 20110223155201
#
# Table name: attachments
#
#  id           :integer(4)      not null, primary key
#  entry_id     :integer(4)      default(0), not null
#  content_type :string(255)
#  filename     :string(255)     default(""), not null
#  size         :integer(4)      default(0), not null
#  type         :string(255)
#  metadata     :string(255)
#  parent_id    :integer(4)
#  thumbnail    :string(255)
#  width        :integer(4)
#  height       :integer(4)
#  user_id      :integer(4)      default(0), not null
#
# Indexes
#
#  index_attachments_on_entry_id   (entry_id)
#  index_attachments_on_parent_id  (parent_id)
#

require File.dirname(__FILE__) + '/../test_helper'

class AttachmentTest < Test::Unit::TestCase
  fixtures :attachments

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
