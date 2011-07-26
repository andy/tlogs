env :MAILTO, 'servers@mmm-tasty.ru'

job_type :bundle, "cd :path && RAILS_ENV=:environment bin/bundle exec :task :output"

every 1.hour do 
  bundle 'rake ts:in:delta'
end

every 1.day, :at => '6:00am' do
  bundle 'rake ts:in'
end

every :reboot do
  bundle 'rake ts:start'
end
