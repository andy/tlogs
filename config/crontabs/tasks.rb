# Run this commands at tasks server (should be only one)
env :MAILTO, 'servers@mmm-tasty.ru'

job_type :bundle, "cd :path && RAILS_ENV=:environment bin/bundle exec :task :output"

every 1.day, :at => '5:00am' do
  bundle 'rake redis:wipe'
end

every :reboot do
  bundle 'rake redis:populate'
end