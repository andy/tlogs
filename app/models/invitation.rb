# == Schema Information
# Schema version: 20120711194752
#
# Table name: invitations
#
#  id         :integer(4)      not null, primary key
#  user_id    :integer(4)      not null, indexed
#  invitee_id :integer(4)      indexed
#  email      :string(255)
#  code       :string(32)      indexed
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_invitations_on_code        (code) UNIQUE
#  index_invitations_on_user_id     (user_id)
#  index_invitations_on_invitee_id  (invitee_id)
#

class Invitation < ActiveRecord::Base
  belongs_to :user
  belongs_to :invitee, :class_name => 'User'
  
  validates_presence_of       :email,
                              :on => :create,
                              :message => 'укажите емейл'

  validates_format_of         :email,
                              :with => Format::EMAIL,
                              :message => 'не похоже на емейл'
  
  validates_uniqueness_of     :code,
                              :on => :create
  
  
  named_scope :revokable, :conditions => 'invitee_id IS NULL'
  named_scope :accepted, :conditions => 'invitee_id IS NOT NULL'


  def validate
    return unless self.email

    if User.find_by_email(self.email)
      errors.add :email, 'пользователь с таким емейлом у нас уже зарегистрирован'
    elsif Invitation.find_by_email(self.email)
      errors.add :email, 'этому пользователю уже высылалось приглашение'
    end
    
    if Disposable::is_disposable_email?(self.email)
      errors.add :email, 'уважаемый, решили поспамить? это запрещенный адрес'
    end
  end
end
