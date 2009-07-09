# comment to entry user's subscribed to
class CommentSubscriptionActivity < Activity
  set_table_name 'comments'
  
  # watchers are people who are subscribed to this entry comments
  has_many :watchers, :foreign_key => 'entry_id', :primary_key => 'entry_id', :class_name => 'FakeEntrySubscriber'
  
  define_index do
    indexes :id

    has :user_id
    has :entry_id
    has :created_at
    has watchers(:user_id), :as => :watcher_ids
    
    where "comments.id > #{Comment.last.id - 1000} AND is_disabled = 0"
  end
end