########
# 
# = Общая активность (базовый класс)
#
# подписался на тлог пользователя
# добавил новую запись
# оставил комментарий
# появилась новая анонимка
# 
class Activity < ActiveRecord::Base
  PER_PAGE = 100
  
  is_activity

  # Базовая активность вытаскивается не только по друзьям
  # (например, активность публикации галерей надо показывать с событий на которых был)
  named_scope :for_user, lambda {|user| {:conditions => ["user_id in (?) OR event_id in (?)", user.activity_user_ids, user.passed_events.ids]}}

end

# Tlog
#   TlogSubscription
#
# Entry
#   EntryCreation +
#   FlowPost +
#   FlowSubscription - v +
#   
# Event
#   EventGo - v +
#   
# Activity
#   Photo - v +
#   Micro +
#   Profile + 
#   Birthday - v +
