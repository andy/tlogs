# encoding: utf-8
# == Schema Information
# Schema version: 20110816190509
#
# Table name: feedbacks
#
#  id           :integer(4)      not null, primary key
#  user_id      :integer(4)      not null, indexed
#  created_at   :datetime        not null, indexed => [is_public], indexed => [is_moderated]
#  updated_at   :datetime        not null
#  message      :text            default(""), not null
#  is_public    :boolean(1)      default(FALSE), not null, indexed => [created_at]
#  is_moderated :boolean(1)      default(FALSE), not null, indexed => [created_at]
#
# Indexes
#
#  index_feedbacks_on_user_id                      (user_id) UNIQUE
#  index_feedbacks_on_is_public_and_created_at     (is_public,created_at)
#  index_feedbacks_on_is_moderated_and_created_at  (is_moderated,created_at)
#

class Feedback < ActiveRecord::Base
  belongs_to :user
  
  # отзывы, ожидающие модерации
  scope :pending, where(:is_moderated => false)
  scope :published, where(:is_public => true)
  scope :random, order('RAND()')
  
  def publish!
    self.update_attributes(:is_public => true, :is_moderated => true)
  end
  
  def discard!
    self.update_attributes(:is_public => false, :is_moderated => true)
  end
  
  def is_owner?(user)
    user && user.id == self.user_id
  end
end
