#!/usr/bin/env script/runner

require 'xmlrpc/client'

trap(:INT) { puts; exit }

$redis.subscribe(:ping) do |on|
  on.subscribe do |channel, subs|
    puts "+ subscribed to channel ##{channel}"
  end

  on.message do |channel, message|
    rt = 0

    begin
      entry = Entry.find(message, :include => { :author => [ :tlog_settings ]})      
    rescue ActiveRecord::RecordNotFound
      if rt > 1
        puts "- failed to find (#{message})"
        next
      end
      rt += 1
      sleep(1)
      retry 
    end
    user  = entry.author
    
    if entry.is_private?
      puts "- skipping private entry (#{user.url}, #{entry.id})"
      next 
    end

    if user.tlog_settings.privacy != 'open'
      puts "- skipping private tlog (#{user.url}, #{entry.id})"
      next
    end
    
    desc = user.url + ' — ' + user.tlog_settings.about

    server = XMLRPC::Client.new2('http://ping.blogs.yandex.ru/RPC2')
    result = server.call('weblogUpdates.ping', desc, "http://#{user.url}.mmm-tasty.ru/")

    if result && result['flerror']
      puts "- ping failed: #{result['message']}"
    else
      puts "+ ping (#{user.url}, #{entry.id})"
    end
  end
end
