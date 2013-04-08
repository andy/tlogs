# == Schema Information
# Schema version: 20120711194752
#
# Table name: changelogs
#
#  id          :integer(4)      not null, primary key
#  owner_id    :integer(4)      not null, indexed, indexed => [action]
#  actor_id    :integer(4)      indexed, indexed => [action]
#  object_id   :integer(4)      indexed => [object_type]
#  object_type :string(255)     indexed => [object_id]
#  action      :string(255)     not null, indexed => [owner_id], indexed => [actor_id]
#  comment     :text
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  index_changelogs_on_object_id_and_object_type  (object_id,object_type)
#  index_changelogs_on_owner_id                   (owner_id)
#  index_changelogs_on_owner_id_and_action        (owner_id,action)
#  index_changelogs_on_actor_id                   (actor_id)
#  index_changelogs_on_actor_id_and_action        (actor_id,action)
#

class Changelog < ActiveRecord::Base
  belongs_to :object, :polymorphic => true
  
  belongs_to :owner, :class_name => 'User'
  
  belongs_to :actor, :class_name => 'User'


  validates_presence_of :owner
  
  validates_presence_of :action
  
  
  named_scope :noauth, { :conditions => 'action != "login" AND action != "session"' }

  named_scope :auth, { :conditions => 'action = "login" OR action = "session"' }  
end
