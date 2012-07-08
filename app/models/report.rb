class Report < ActiveRecord::Base
  belongs_to :reporter, :class_name => 'User', :foreign_key => 'reporter_id'
  
  belongs_to :content, :polymorphic => true
  
  belongs_to :content_owner, :class_name => 'User', :foreign_key => 'content_owner_id'
  
  
  validates_presence_of :reporter
  
  validates_presence_of :content
  
  validates_presence_of :content_owner
  
  validates_uniqueness_of :content_id, :scope => [:reporter_id, :content_type]
  
  named_scope :comments, :conditions => 'content_type = "Comment"'
  named_scope :entries, :conditions => 'content_type = "Entry"'
  
  named_scope :all_inclusive, :include => [:reporter, :content, :content_owner]
  
  def content_uuid
    content_type + '#' + content_id.to_s
  end
  
  def content_excerpt
    case content_type
    when 'Comment'
      content.comment
    else
      'not supported'
    end
  end
end
