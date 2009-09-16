# - мои друзья добавили чей-то пост в избранное
class FaveActivity < Activity
  set_table_name 'faves'
  
  # watchers are people who are subscribed to this author tlog
  has_many :watchers, :foreign_key => 'user_id', :primary_key => 'user_id', :class_name => 'Relationship', :conditions => 'relationships.friendship_status > 0'
  
  # define_index do
  #   indexes :id
  # 
  #   has :user_id
  #   has :created_at
  #   has watchers(:reader_id), :as => :watcher_ids
  #   
  #   where "faves.id > #{Fave.last.id - 1000}"
  # end
end