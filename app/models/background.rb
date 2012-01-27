# encoding: utf-8
# == Schema Information
# Schema version: 20111213165134
#
# Table name: backgrounds
#
#  id               :integer(4)      not null, primary key
#  user_id          :integer(4)      not null, indexed
#  image_file_name  :string(255)     not null
#  image_updated_at :datetime
#  image_meta       :text
#  is_public        :boolean(1)      default(FALSE), not null
#  created_at       :datetime
#  updated_at       :datetime
#  gray_logo        :boolean(1)      default(FALSE), not null
#
# Indexes
#
#  index_backgrounds_on_user_id  (user_id)
#

class Background < ActiveRecord::Base
  ## included modules & attr_*
  ## associations
  belongs_to  :user

  has_many    :tlog_settings, :class_name => 'TlogSettings'


  ## plugins
  has_attached_file :image,
    :url              => '/assets/bgs/:sha1_partition/:id_:style.:extension',
    :path             => ':rails_root/public:url',
    :convert_options  => { :all => '-strip' },
    :use_timestamp    => false

  
  ## scopes
  scope :public, where(:is_public => true)


  ## validations
  validates_presence_of :user

  
  ## callbacks
  ## class methods
  ## public methods
  ## private methods
end
