# == Schema Information
# Schema version: 20110223155201
#
# Table name: tlog_backgrounds
#
#  id                      :integer(4)      not null, primary key
#  tlog_design_settings_id :integer(4)
#  content_type            :string(255)
#  filename                :string(255)
#  size                    :integer(4)
#  parent_id               :integer(4)
#  thumbnail               :string(255)
#  width                   :integer(4)
#  height                  :integer(4)
#  db_file_id              :integer(4)
#
# Indexes
#
#  index_tlog_backgrounds_on_tlog_design_settings_id  (tlog_design_settings_id)
#  index_tlog_backgrounds_on_parent_id                (parent_id)
#

require File.dirname(__FILE__) + '/../test_helper'

class TlogBackgroundTest < Test::Unit::TestCase
  fixtures :tlog_backgrounds

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
