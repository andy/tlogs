#!/usr/bin/env script/runner

user_id = 120372
c = Comment.find_by_user_id user_id
if c.nil?
  puts "+ nothing"
  exit
end

e = c.entry

puts "+ delete all comments on entry #{e.id} by #{user_id}"
puts "+ total comments #{e.comments_count}, bad comments #{Comment.count(:conditions => "user_id = #{user_id} AND entry_id = #{e.id}")}"
Comment.delete_all ["user_id = ? AND entry_id = ?", user_id, e.id]

e.comments_count = e.comments.count
e.save(false)

puts "+ total comments #{e.comments_count} (#{e.comments.count}), bad comments #{Comment.count(:conditions => "user_id = #{user_id} AND entry_id = #{e.id}")}"

