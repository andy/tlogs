class Background < ActiveRecord::Base
  ## included modules & attr_*
  ## associations
  belongs_to  :user

  has_many    :tlog_settings, :class_name => 'TlogSettings'


  ## plugins
  has_attached_file :image,
    :url            => '/assets/bgs/:sha1_partition/:id_:style.:extension',
    :path           => ':rails_root/public:url',
    :use_timestamp  => false

  
  ## named_scopes
  named_scope :public, :conditions => { :is_public => true }


  ## validations
  validates_presence_of :user

  
  ## callbacks
  ## class methods
  ## public methods
  ## private methods
end