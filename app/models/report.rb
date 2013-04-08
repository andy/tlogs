# == Schema Information
# Schema version: 20120711194752
#
# Table name: reports
#
#  id               :integer(4)      not null, primary key
#  reporter_id      :integer(4)      not null, indexed => [content_id, content_type], indexed
#  content_id       :integer(4)      not null, indexed => [reporter_id, content_type], indexed => [content_type]
#  content_type     :string(255)     not null, indexed => [reporter_id, content_id], indexed => [content_id]
#  content_owner_id :integer(4)      not null, indexed
#  created_at       :datetime
#  updated_at       :datetime
#
# Indexes
#
#  index_reports_on_reporter_id_and_content_id_and_content_type  (reporter_id,content_id,content_type) UNIQUE
#  index_reports_on_reporter_id                                  (reporter_id)
#  index_reports_on_content_owner_id                             (content_owner_id)
#  index_reports_on_content_id_and_content_type                  (content_id,content_type)
#

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

  named_scope :all_inclusive, :include => [:reporter, :content_owner]

  def excerpt
    case content_type
    when 'Comment'
      content.try(:comment) || ''
    else
      'not supported'
    end
  end
end
