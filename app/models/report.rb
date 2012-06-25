class Report < ActiveRecord::Base
  belongs_to :reporter, :class_name => 'User'
  
  belongs_to :content, :polymorphic => true
  
  belongs_to :content_owner, :class_name => 'User'
  
  
  validates_presence_of :reporter
  
  validates_presence_of :content
  
  validates_presence_of :content_owner
  
  validates_uniqueness_of :content_id, :scope => [:reporter_id, :content_type]
end
