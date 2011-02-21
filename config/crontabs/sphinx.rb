env :MAILTO, 'servers@mmm-tasty.ru'

every 1.hour do 
  rake 'ts:in:delta'
end

every 1.day, :at => '6:00am' do
  rake 'ts:in'
end

every :reboot do
  rake 'ts:start'
end
