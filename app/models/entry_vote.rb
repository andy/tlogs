# == Schema Information
# Schema version: 20110223155201
#
# Table name: entry_votes
#
#  id       :integer(4)      not null, primary key
#  entry_id :integer(4)      default(0), not null
#  user_id  :integer(4)      default(0), not null
#  value    :integer(4)      default(0), not null
#
# Indexes
#
#  index_entry_votes_on_entry_id_and_user_id  (entry_id,user_id) UNIQUE
#

# это голос одного пользователя
class EntryVote < ActiveRecord::Base
  belongs_to :entry
  belongs_to :user

  validates_presence_of :user_id
  validates_presence_of :entry_id
  
  named_scope :positive, { :conditions => 'value > 0' }
  named_scope :negative, { :conditions => 'value < 0' }  
end
