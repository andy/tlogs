# = Schema Information
#
# Table name: *avatars*
#
#  id           :integer(4)      not null, primary key
#  user_id      :integer(4)      default(0), not null
#  content_type :string(255)
#  filename     :string(255)
#  size         :integer(4)
#  position     :integer(4)
#  parent_id    :integer(4)
#  thumbnail    :string(255)
#  width        :integer(4)
#  height       :integer(4)
########
class Avatar < ActiveRecord::Base
  belongs_to :user

  has_attachment :storage => :file_system, :max_size => 4.megabytes, :content_type => :image, :resize_to => '64x64>', :file_system_path => 'public/uc/avt'
  validates_as_attachment
  
  # acts_as_list :scope => :user
  
  validates_presence_of :user_id
  
  def full_filename(thumbnail = nil)
    file_system_path = (thumbnail ? thumbnail_class : self).attachment_options[:file_system_path]
    File.join(RAILS_ROOT, file_system_path, tasty_attachment_path(filename), "#{id}_#{user_id}_" + thumbnail_name_for(thumbnail))
  end
  
  def tasty_attachment_path(filename)
    File.join(Digest::SHA1.hexdigest(filename)[0..1], Digest::SHA1.hexdigest(filename)[2..3])
  end

end
