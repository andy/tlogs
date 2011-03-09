# == Schema Information
# Schema version: 20110223155201
#
# Table name: sidebar_sections
#
#  id       :integer(4)      not null, primary key
#  user_id  :integer(4)      not null
#  name     :string(255)     not null
#  position :integer(4)
#  is_open  :boolean(1)      default(FALSE), not null
#
# Indexes
#
#  index_sidebar_sections_on_user_id_and_position  (user_id,position)
#

class SidebarSection < ActiveRecord::Base
  belongs_to :user
  has_many :elements, :class_name => 'SidebarElement', :order => :position, :dependent => :destroy
  
  validates_presence_of :name
  validates_associated :user
end
