#!/usr/bin/env script/runner

page_size = Entry::PAGE_SIZE
limit     = (EntryRating::DAY_LIMIT * 4 / page_size).round

(0..limit).each do |page|
  ers_ids = EntryRating.find(:all, :select => 'entry_ratings.id', :offset => (page*page_size), :limit => page_size, :order => 'entry_ratings.id DESC').map(&:id)

  ers = EntryRating.find_all_by_id(ers_ids, :include => [:entry])

  ers.each do |er|
    er.transaction do
      er.ups    = er.entry.votes.positive.count
      er.downs  = er.entry.votes.negative.count
      er.send(:update_hotness)
      er.save!
    end
  end
end
