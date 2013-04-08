env :MAILTO, 'servers@mmm-tasty.ru'
env :PATH, '/usr/local/bin:/usr/bin:/bin:/var/lib/gems/1.8/bin:/usr/local/node/bin:/var/lib/gems/1.8/bin:/usr/local/node/bin'

job_type :bundle, "cd :path && RAILS_ENV=:environment bundle exec :task :output"

every 1.hour do
  bundle 'rake -s ts:in:delta'
end

every 1.day, :at => '6:00am' do
  bundle 'rake -s ts:in'
end

every :reboot do
  bundle 'rake ts:start'
end
