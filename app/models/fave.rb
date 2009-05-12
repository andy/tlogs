# = Schema Information
#
# Table name: *faves*
#
#  id            :integer(4)      not null, primary key
#  user_id       :integer(4)      not null
#  entry_id      :integer(4)      not null
#  entry_type    :string(64)      not null
#  entry_user_id :integer(4)      not null
#  created_at    :datetime
########
class Fave < ActiveRecord::Base
  belongs_to :user, :counter_cache => true
  belongs_to :entry
  
  def is_owner?(user)
    user.id == self.user_id
  end
end
