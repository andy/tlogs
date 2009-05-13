# = Schema Information
#
# Table name: *feedbacks*
#
#  id           :integer(4)      not null, primary key
#  user_id      :integer(4)      not null
#  created_at   :datetime        not null
#  updated_at   :datetime        not null
#  message      :text            default(""), not null
#  is_public    :boolean(1)      not null
#  is_moderated :boolean(1)      not null
########
class Feedback < ActiveRecord::Base
  belongs_to :user
  
  # отзывы, ожидающие модерации
  named_scope :pending, :conditions => { :is_moderated => false }
  named_scope :published, :conditions => { :is_public => true }
  named_scope :random, :order => 'RAND()'
  
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
