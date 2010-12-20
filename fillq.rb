#!/usr/bin/env ruby script/runner

entry_min_id = Entry.last.id

# First, update all entries
(1..200).each do |page|
  puts "page #{page}"
  Entry.paginate(:page => page, :per_page => 50, :include => [:author], :order => 'id desc').each do |entry|
    # puts "update entry #{entry.id}"
    entry.try_watchers_update
    entry_min_id = [entry_min_id, entry.id].min
  end
end

# Then, go by comments to bring old stuff up. Ignore comments on newer entries, as that will not change much
(1..200).each do |page|
  puts "page #{page}"
  Comment.paginate(:page => page, :per_page => 100, :order => 'id desc').each do |comment|
    if comment.entry_id < entry_min_id
      puts "updating on comment #{comment.entry_id}"
      comment.entry.try_watchers_update
    end
  end
end
