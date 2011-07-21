# Run this commands at tasks server (should be only one)
env :MAILTO, 'servers@mmm-tasty.ru'

every 1.day, :at => '5:00am' do
  rake 'redis:wipe'
end

every :reboot do
  rake 'redis:populate'
end