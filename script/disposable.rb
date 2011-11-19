#!/usr/bin/env script/runner

MAX_ID = User.last.id - 20000
user_ids = []
User.paginated_each(:per_page => 100, :conditions => "users.id > #{MAX_ID}") do |user|
  if Disposable.is_disposable_email?(user.email)
    puts "+ #{user.id} #{user.email}, #{user.url}" 
    user_ids << user.id
  end
end

user_ids.each do |uid|
  user = User.find(uid)
  puts "- #{user.id} #{user.email}, #{user.url}"
  user.destroy
end

