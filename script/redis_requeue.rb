#!/usr/bin/env script/runner

# rebuild redis queue from last entries

page_size = 30
(0..1000).each do |page|
  entry_ids = Entry.find(:all, :select => 'entries.id', :offset => (page*page_size), :limit => page_size, :order => 'entries.id DESC')

  puts "page #{page}, requeueing #{entry_ids.map(&:id).join(', ')}"

  entries = Entry.find_all_by_id(entry_ids.map(&:id))  
  entries.map(&:try_watchers_update)
end
