# == Schema Information
# Schema version: 20110223155201
#
# Table name: users
#
#  id                      :integer(4)      not null, primary key
#  email                   :string(255)
#  is_confirmed            :boolean(1)      default(FALSE), not null
#  openid                  :string(255)
#  url                     :string(255)     default(""), not null
#  settings                :text
#  is_disabled             :boolean(1)      default(FALSE), not null
#  created_at              :datetime        not null
#  entries_count           :integer(4)      default(0), not null
#  updated_at              :datetime
#  is_anonymous            :boolean(1)      default(FALSE), not null
#  is_mainpageable         :boolean(1)      default(FALSE), not null
#  is_premium              :boolean(1)      default(FALSE), not null
#  domain                  :string(255)
#  private_entries_count   :integer(4)      default(0), not null
#  email_comments          :boolean(1)      default(TRUE), not null
#  comments_auto_subscribe :boolean(1)      default(TRUE), not null
#  gender                  :string(1)       default("m"), not null
#  username                :string(255)
#  salt                    :string(40)
#  crypted_password        :string(40)
#  faves_count             :integer(4)      default(0), not null
#  entries_updated_at      :datetime
#  conversations_count     :integer(4)      default(0), not null
#
# Indexes
#
#  index_users_on_email                           (email)
#  index_users_on_openid                          (openid)
#  index_users_on_url                             (url)
#  index_users_on_domain                          (domain)
#  index_users_on_is_confirmed                    (is_confirmed)
#  index_users_on_entries_count                   (entries_count)
#  index_users_on_is_confirmed_and_entries_count  (is_confirmed,entries_count)
#

require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
  fixtures :users

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
