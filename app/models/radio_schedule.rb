class RadioSchedule < ActiveRecord::Base
  belongs_to :user
  
  default_scope :order => 'air_at DESC'

  attr_accessor :duration
  
  named_scope :onair, { :conditions => "end_at >= NOW()", :order => 'air_at ASC', :limit => 3 }

  validates_presence_of :air_at
  
  validates_presence_of :end_at

  validates_presence_of :user_id
  
  validates_length_of :body, :within => 3..200, :too_short => 'описание не может быть короче 3 символов', :too_long => 'описание не может быть длиннее 200 символов'
  
  
  # set ending period from virtual duration attribute
  before_validation do |record|
    record.end_at = record.air_at + record.duration.to_i.minutes unless record.duration.blank?
  end
  
  def onair?
    self.air_at < Time.now && self.end_at > Time.now
  end
  
  def self.djs
    djs = []
    djs << User.find_by_url('radio').try(:id)
    djs << User.find_by_url('radio').public_friend_ids
    djs << User.admins
    djs.flatten.compact
  end
  
  def is_owner?(user)
    # user can remove his own records
    allowed_users = [user.id]
    
    # also radio owner & global administrators can
    allowed_users << User.find_by_url('radio').try(:id)
    allowed_users << User.admins
    
    allowed_users.flatten.compact.include?(self.user_id)
  end
end
