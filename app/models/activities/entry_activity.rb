# мои друзья написали запись
class EntryActivity < Activity
  set_table_name 'entries'

  # watchers are people who are subscribed to entry author tlog
  has_many :watchers, :foreign_key => 'user_id', :primary_key => 'user_id', :class_name => 'Relationship', :conditions => 'relationships.friendship_status > 0'  
  
  # define_index do
  #   indexes :type
  #   
  #   has :user_id
  #   has :created_at
  #   has watchers(:reader_id), :as => :watcher_ids
  #   
  #   where "entries.is_disabled = 0 AND entries.is_private = 0 AND entries.id > #{Entry.last.id - 1000}"
  # 
  #   set_property :sql_range_step => 500
  # end
end