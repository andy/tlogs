# = Schema Information
#
# Table name: *relationships*
#
#  id                        :integer(4)      not null, primary key
#  user_id                   :integer(4)      default(0), not null
#  reader_id                 :integer(4)      default(0), not null
#  position                  :integer(4)
#  read_count                :integer(4)      default(0), not null
#  last_read_at              :datetime
#  comment_count             :integer(4)      default(0), not null
#  last_comment_at           :datetime
#  friendship_status         :integer(4)      default(0), not null
#  votes_value               :integer(4)      default(0), not null
#  last_viewed_at            :datetime
#  last_viewed_entries_count :integer(4)      default(0), not null
#  title                     :string(128)
########
class Relationship < ActiveRecord::Base
  # есть пользователь :user которого читает другой пользователь, :reader
  belongs_to :user
  belongs_to :reader, :class_name => 'User', :foreign_key => 'reader_id'
  
  validates_presence_of :user_id
  validates_presence_of :reader_id
  validates_inclusion_of :friendship_status, :in => -1..2
  
  acts_as_list :scope => 'reader_id = #{reader_id} AND friendship_status = #{friendship_status}'
  
  PUBLIC = 2
  DEFAULT = 1
  GUESSED = 0
  IGNORED = -1
  
  def say_it(user, reader)
    case friendship_status
    when PUBLIC
      user.gender('Он у тебя в друзьях', 'Она у тебя в друзьях')
    when DEFAULT
      reader.gender("Ты подписан на #{user.gender('его', 'её')} тлог", "Ты подписана на #{user.gender('его', 'её')} тлог")
    else
      "Подписаться на #{user.gender('его', 'её')} тлог"
    end
  end  
end
