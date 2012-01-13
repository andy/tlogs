env :MAILTO, 'servers@mmm-tasty.ru'
env :PATH, '/usr/local/bin:/usr/bin:/bin:/var/lib/gems/1.8/bin:/usr/local/node/bin:/var/lib/gems/1.8/bin:/usr/local/node/bin'

job_type :god, "cd :path && RAILS_ENV=:environment RAILS_ROOT=:path god :task :output"

every :reboot do
  god "-c config/god/resque.god start"
end
