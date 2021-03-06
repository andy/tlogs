# == Schema Information
# Schema version: 20110816190509
#
# Table name: comment_views
#
#  id                  :integer(4)      not null, primary key
#  entry_id            :integer(4)      default(0), not null, indexed => [user_id]
#  user_id             :integer(4)      default(0), not null, indexed => [entry_id]
#  last_comment_viewed :integer(4)      default(0), not null
#
# Indexes
#
#  index_comment_views_on_entry_id_and_user_id  (entry_id,user_id) UNIQUE
#

class CommentViews < ActiveRecord::Base
  belongs_to :entry
  belongs_to :user

  validates_presence_of :entry_id
  validates_presence_of :user_id
  validates_presence_of :last_comment_viewed

  # Пользователь user просмотрел запись entry
  def self.view(entry, user)
    if entry.comments.size
      cv = CommentViews.find_or_initialize_by_entry_id_and_user_id(entry.id, user.id)
      last_comment_viewed = cv.last_comment_viewed
      if cv.last_comment_viewed != entry.comments.size
        cv.last_comment_viewed = entry.comments.size
        begin
          cv.save
        rescue ActiveRecord::StatementInvalid
          # ignore dup key error
          # Mysql::Error: Duplicate entry '548679-18691' for key 2: INSERT INTO `comment_views` (`entry_id`, `last_comment_viewed`, `user_id`) VALUES(548679, 2, 18691)
        end
      end
      last_comment_viewed
    else
      0
    end
  end
end
