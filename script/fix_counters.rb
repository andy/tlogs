#!/usr/bin/env script/runner

def fix_counters_for(user)
  User.transaction do
    user.reload

    # entries_count
    ec = user.entries.count
    puts "! #{user.id} entries #{user.entries_count} should be #{ec}" if ec != user.entries_count
  
    # private entries count
    pec = user.entries.count(:conditions => 'is_private = 1')
    puts "! #{user.id} private entries #{user.private_entries_count} should be #{pec}" if pec != user.private_entries_count
 
    # run query
    user.entries_count          = ec
    user.private_entries_count  = pec

    user.save(false) if (['entries_count', 'private_entries_count'] & user.changes.keys).any?


    # conversations count
    cc = user.conversations.count
    if cc != user.conversations_count
      puts "! #{user.id} convos #{user.conversations_count} should be #{cc}"
      user.connection.execute("UPDATE users SET conversations_count = #{cc} WHERE id = #{user.id}")
    end
  
    # faves count
    fc = user.faves.count
    if fc != user.faves_count
      puts "! #{user.id} faves #{user.faves_count} should be #{fc}"
  
      # execute directly as fc is protected
      user.connection.execute("UPDATE users SET faves_count = #{fc} WHERE id = #{user.id}")
    end
  end  
end

if ARGV.blank?
  puts "+ fixing counters for all active users"
  User.paginated_each { |user| fix_counters_for(user) }
else
  puts "+ fixing counters for user #{ARGV[0]}"
  fix_counters_for(User.find_by_url(ARGV[0]))
end
