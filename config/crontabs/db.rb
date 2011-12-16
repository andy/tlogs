env :MAILTO, 'servers@mmm-tasty.ru'

job_type :bundle, "cd :path && RAILS_ENV=:environment bin/bundle exec :task :output"

# Notify about expiring premium
every 1.day, :at => '4:00am' do
  bundle 'script/premium_will_expire'
end

every 1.day, :at => '5:00am' do
  bundle 'script/premium_expired'
end
