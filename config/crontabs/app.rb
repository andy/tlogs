env :MAILTO, 'servers@mmm-tasty.ru'

# Remove rack uploads trash
every 1.day do
  command "find /tmp/ -maxdepth 1 -type f -name RackMultipart\\* -ctime +1 -print0 -user tasty | xargs -0 rm"
end

every :reboot do
  command "cd :path && RAILS_ENV=:environment bundle exec unicorn_rails -c config/unicorn.rb -E production -D"
end