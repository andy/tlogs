env :MAILTO, 'servers@mmm-tasty.ru'

every :reboot do
  command "cd :path && RAILS_ENV=:environment RAILS_ROOT=:path bin/bundle exec god"
  command "cd :path && RAILS_ENV=:environment RAILS_ROOT=:path bin/bundle exec god load config/god/resque.god"
end
