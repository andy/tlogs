env :MAILTO, 'servers@mmm-tasty.ru'

every :reboot do
  command "cd #{RAILS_ROOT} && bin/bundle exec god"
  command "cd #{RAILS_ROOT} && bin/bundle exec god load config/god/resque.god"
end
