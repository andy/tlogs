#!/usr/bin/env script/runner

require 'xmlrpc/client'

trap(:INT) { puts; exit }

counter = {}

def efetch(entry_id)
  begin
    entry = Entry.find(entry_id, :include => { :author => [ :tlog_settings ]})
  rescue ActiveRecord::RecordNotFound
    return nil
  end
  user  = entry.author

  if entry.is_private?
    puts "- skipping private entry (#{user.url}, #{entry.id})"
    return false
  end

  if user.tlog_settings.privacy != 'open'
    puts "- skipping private tlog (#{user.url}, #{entry.id})"
    return false
  end

  entry
end

def yaping(user, entry)
  desc = user.url
  desc += ' — ' + user.tlog_settings.about unless user.tlog_settings.about.blank?

  server = XMLRPC::Client.new2('http://ping.blogs.yandex.ru/RPC2')
  begin
    result = server.call('weblogUpdates.ping', desc, "http://#{user.url}.mmm-tasty.ru/feed/rss.xml")
  rescue Exception => ex
    puts "- ping failed: #{ex.class.name}: #{ex.message}"
    return
  end

  if result && result['flerror']
    puts "- ping failed: #{result['message']}"
  elsif result
    puts "+ ping (#{user.url}, #{entry.id})"
  else
    puts "- ping failed: unknown reason"
  end
end

$redis.subscribe(:ping) do |on|
  on.subscribe do |channel, subs|
    puts "+ subscribed to channel ##{channel}"
  end

  on.message do |channel, message|
    rt = 0

    entries = []

    # Load entries to retry ping with
    counter.keys.each do |entry_id|
      if counter[entry_id] > 30
        puts "- entry not found (#{entry_id})"
  counter.delete entry_id
      else
  entry = efetch(entry_id)
  if entry.nil?
    counter[entry_id] += 1
  elsif entry
    counter.delete entry_id
    entries << entry
  else
    counter.delete entry_id
  end
      end
    end

    # Load current entry
    entry = efetch(message)
    if entry.nil?
      counter[message] = 1
    elsif entry
      entries << entry
    end

    # Now ping all entries we've collected
    entries.each do |entry|
      yaping(entry.author, entry)
      counter.delete entry.id
    end
  end
end
