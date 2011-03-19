env :MAILTO, 'servers@mmm-tasty.ru'

job_type :god, "cd :path && RAILS_ENV=:environment RAILS_ROOT=:path god :task :output"

every :reboot do
  god "-c config/god/resque.god start"
end
