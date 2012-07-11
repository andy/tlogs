class Changelog < ActiveRecord::Base
  belongs_to :object, :polymorphic => true
  
  belongs_to :owner, :class_name => 'User'
  
  belongs_to :actor, :class_name => 'User'


  validates_presence_of :owner
  
  validates_presence_of :action
end
