# = Schema Information
#
# Table name: *sidebar_sections*
#
#  id       :integer(4)      not null, primary key
#  user_id  :integer(4)      not null
#  name     :string(255)     not null
#  position :integer(4)
#  is_open  :boolean(1)      not null
########
class SidebarSection < ActiveRecord::Base
  belongs_to :user
  has_many :elements, :class_name => 'SidebarElement', :order => :position, :dependent => :destroy
  
  validates_presence_of :name
  validates_associated :user
end
