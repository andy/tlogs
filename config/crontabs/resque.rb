env :MAILTO, 'servers@mmm-tasty.ru'

job_type :bundle, "cd :path && RAILS_ENV=:environment bin/bundle exec :task :output"

every :reboot do
  bundle "god -c config/god/resque.god start"
end
