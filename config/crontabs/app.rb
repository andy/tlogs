env :MAILTO, 'servers@mmm-tasty.ru'
env :PATH, '/usr/local/bin:/usr/bin:/bin:/var/lib/gems/1.8/bin:/usr/local/node/bin:/var/lib/gems/1.8/bin:/usr/local/node/bin'

job_type :bundle, "cd :path && source .reerc && RAILS_ENV=:environment bundle exec :task :output"

# Remove rack uploads trash
every 1.day do
  command "find /tmp/ -maxdepth 1 -type f -name RackMultipart\\* -ctime +1 -print0 -user tasty | xargs -0 rm 2>/dev/null"
  command "find /tmp/ -maxdepth 1 -type f -name mini_magick\\* -ctime +1 -print0 -user tasty | xargs -0 rm 2>/dev/null"
end

every :reboot do
  bundle "unicorn_rails -c config/unicorn.rb -E production -D"
end