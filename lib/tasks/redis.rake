namespace :redis do
  desc "Wipe old entries out"
  task :wipe => :environment do
    # clean old entries in users queue
    m = 500
    $redis.keys('u:*:q').each do |k|
      c = $redis.zcard(k)
      next if c <= m

      $redis.zremrangebyrank k, 0, (c-m-1)
    end

    # clean old entries in neighborhood queue
    m = 1000
    $redis.keys('n:*').each do |k|
      c = $redis.zcard(k)
      next if c <= m

      $redis.zremrangebyrank k, 0, (c-m-1)
    end
  end
  
  desc "Populate redis queues with entries"
  task :populate => :environment do
    page_size = 30
    (0..1000).each do |page|
      entry_ids = Entry.find(:all, :select => 'entries.id', :offset => (page*page_size), :limit => page_size, :order => 'entries.id DESC')

      # puts "page #{page}, requeueing #{entry_ids.map(&:id).join(', ')}"

      entries = Entry.find_all_by_id(entry_ids.map(&:id))  
      entries.map(&:try_watchers_update)
    end
  end
end