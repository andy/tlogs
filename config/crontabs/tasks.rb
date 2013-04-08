# Run this commands at tasks server (should be only one)
env :MAILTO, 'servers@mmm-tasty.ru'
env :PATH, '/usr/local/bin:/usr/bin:/bin:/var/lib/gems/1.8/bin:/usr/local/node/bin:/var/lib/gems/1.8/bin:/usr/local/node/bin'

job_type :bundle, "cd :path && RAILS_ENV=:environment bundle exec :task :output"

every 1.day, :at => '5:00am' do
  bundle 'rake redis:wipe'
end

every :reboot do
  bundle 'rake redis:populate'
end
