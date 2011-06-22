#!/usr/bin/env bundle exec script/runner

User.paginated_each do |user|
  User.transaction do
    user.reload

    # entries_count
    ec = user.entries.count
    puts "! #{user.id} entries #{user.entries_count} should be #{ec}" if ec != user.entries_count
  
    # private entries count
    pec = user.entries.count(:conditions => 'is_private = 1')
    puts "! #{user.id} private entries #{user.private_entries_count} should be #{pec}" if pec != user.private_entries_count
  
    # conversations count
    cc = user.conversations.count
    puts "! #{user.id} convos #{user.conversations_count} should be #{cc}" if cc != user.conversations_count
  
    # run query
    user.entries_count          = ec
    user.private_entries_count  = pec
    user.conversations_count    = cc

    user.save(false) if (['entries_count', 'private_entries_count', 'conversations_count'] & user.changes.keys).any?
  
    # faves count
    fc = user.faves.count
    if fc != user.faves_count
      puts "! #{user.id} faves #{user.faves_count} should be #{fc}" if fc != user.faves_count
  
      # execute directly as fc is protected
      user.connection.execute("UPDATE users SET faves_count = #{fc} WHERE id = #{user.id}") if fc != user.faves_count
    end
  end
end