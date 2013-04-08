env :MAILTO, 'servers@mmm-tasty.ru'
env :PATH, '/usr/local/bin:/usr/bin:/bin:/var/lib/gems/1.8/bin:/usr/local/node/bin:/var/lib/gems/1.8/bin:/usr/local/node/bin'

job_type :bundle, "cd :path && source .reerc && RAILS_ENV=:environment bundle exec :task :output"

# Remove rack uploads trash
every 10.minutes do
  command "find /tmp/ -maxdepth 1 -type f -name RackMultipart\\* -cmin +10 -print0 -user tasty | xargs -r0 rm 2>/dev/null"
  command "find /tmp/ -maxdepth 1 -type d -name RackMultipart\\*.lock -cmin +10 -print0 -user tasty | xargs -r0 rm -r 2>/dev/null"
  command "find /tmp/ -maxdepth 1 -type f -name mini_magick\\* -cmin +10 -print0 -user tasty | xargs -r0 rm 2>/dev/null"
  command "find /tmp/ -maxdepth 1 -type d -name mini_magick\\*.lock -cmin +10 -print0 -user tasty | xargs -r0 rm -r 2>/dev/null"

  command "find /tmp/ -maxdepth 1 -type f -name stream\\* -cmin +10 -print0 -user tasty | xargs -r0 rm 2>/dev/null"
end

every :reboot do
  bundle "unicorn_rails -c config/unicorn.rb -E production -D"
end