class Invitation < ActiveRecord::Base
  belongs_to :user
  belongs_to :invitee, :class_name => User
  
  validates_presence_of       :email,
                              :on => :create,
                              :message => 'укажите емейл'

  validates_format_of         :email,
                              :with => Format::EMAIL,
                              :message => 'не похоже на емейл'
  
  validates_uniqueness_of     :code,
                              :on => :create
  
  
  named_scope :revokable, :conditions => 'invitee_id IS NULL'


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