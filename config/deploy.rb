# This defines a deployment "recipe" that you can feed to capistrano
# (http://manuals.rubyonrails.com/read/book/17). It allows you to automate
# (among other things) the deployment of your application.

# =============================================================================
# REQUIRED VARIABLES
# =============================================================================
# You must always specify the application and repository for every recipe. The
# repository must be the URL of the repository you want this recipe to
# correspond to. The deploy_to path must be the path on each machine that will
# form the root of the application path.

set :scm, 'git'
set :application, 'tasty'
set :repository, 'git://github.com/andy/tlogs.git'

# =============================================================================
# ROLES
# =============================================================================
# You can define any number of roles, each of which contains any number of
# machines. Roles might include such things as :web, or :app, or :db, defining
# what the purpose of each machine is. You can also specify options that can
# be used to single out a specific subset of boxes in a particular role, like
# :primary => true.

role :db, "f1.tlogs.ru", :primary => true
role :app, 'f1.tlogs.ru', 'f2.tlogs.ru', 'f3.tlogs.ru'
role :web, 'f2.tlogs.ru'
role :redis, 'f1.tlogs.ru'
role :cache, 'f1.tlogs.ru', 'f2.tlogs.ru'
role :sphinx, 'f1.tlogs.ru'
role :resque, 'f1.tlogs.ru'
role :tasks, 'f1.tlogs.ru'
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
# =============================================================================
# OPTIONAL VARIABLES
# =============================================================================
set :deploy_to, '/home/tasty/tlogs-git' # defaults to "/u/apps/#{application}"
set :user, 'tasty'                      # defaults to the currently logged in user

# =============================================================================
# SSH OPTIONS
# =============================================================================
ssh_options[:user] = 'tasty'
ssh_options[:port] = 22

# =============================================================================
# TASKS
# =============================================================================
# Define tasks that run on all (or only some) of the machines. You can specify
# a role (or set of roles) that each task should be executed on. You can also
# narrow the set of servers to a subset of a role by specifying options, which
# must match the options given for the servers to select (like :primary => true)


namespace :deploy do
  desc "Update and restart web server"
  task :default do
    git.pull
    bundle.install
    sphinx.conf
    resque.restart
    web.restart
    cache.flush
    cron.update
  end
  
  desc "Update sources, but do not restart server"
  task :light do
    git.pull
    bundle.install
    sphinx.conf
    assets.glue
    cache.flush
    cron.update
  end
  
  desc "Use this deploy when only views have changed"
  task :views do
    git.pull
    web.restart
    cache.flush
  end
  
  desc "Use this deploy when only code has changed"
  task :code do
    git.pull
    web.reload
  end
  
  namespace :cron do
    desc "Update all crontab files"
    task :update do
      cron.db
      cron.app
      cron.sphinx
      cron.resque
      cron.tasks_crontab
    end
    
    task :db, :roles => :db do
      run "cd #{deploy_to} && RAILS_ENV=production bin/whenever -f config/crontabs/db.rb -i db"
    end

    task :app, :roles => :app do
      run "cd #{deploy_to} && RAILS_ENV=production bin/whenever -f config/crontabs/app.rb -i app"
    end

    task :sphinx, :roles => :sphinx do
      run "cd #{deploy_to} && RAILS_ENV=production bin/whenever -f config/crontabs/sphinx.rb -i sphinx"
    end

    task :resque, :roles => :resque do
      run "cd #{deploy_to} && RAILS_ENV=production bin/whenever -f config/crontabs/resque.rb -i resque"
    end
    
    task :tasks_crontab, :roles => :tasks do
      run "cd #{deploy_to} && RAILS_ENV=production bin/whenever -f config/crontabs/tasks.rb -i tasks"
    end
  end
  
  namespace :git do
    desc "Update sources from git"
    task :pull, :roles => :app do
      run "cd #{deploy_to} && git checkout db/schema.rb"
      run "cd #{deploy_to} && git pull origin master"
    end
  end
  
  namespace :sphinx do
    desc "Sphinx conf"
    task :conf, :roles => :app do
      run "cd #{deploy_to} && RAILS_ENV=production bundle exec rake ts:conf"
    end
    
    desc "Start sphinx"
    task :start, :roles => :sphinx do
      run "cd #{deploy_to} && RAILS_ENV=production bundle exec rake ts:start"
    end
    
    desc "Stop sphinx"
    task :stop, :roles => :sphinx do
      run "cd #{deploy_to} && RAILS_ENV=production bundle exec rake ts:stop"
    end
    
    desc "Reindex"
    task :reindex, :roles => :sphinx do
      run "cd #{deploy_to} && RAILS_ENV=production bundle exec rake ts:reindex"
    end
  end
  
  namespace :cache do
    desc "Flush memcache"
    task :flush, :roles => :cache do
      run "echo flush_all | nc -q 1 localhost 11211"
    end
  end
  
  namespace :web do
    desc "Restart webserver"
    task :restart, :roles => :app do
      assets.glue_temp
      web.reload
      assets.deploy
    end
    
    task :reload, :roles => :app do
      run "cd #{deploy_to} && kill -USR2 `cat tmp/pids/unicorn.pid`"
    end
    
    desc "Stop webserver"
    task :stop, :roles => :app do
      run "cd #{deploy_to} && kill -QUIT `cat tmp/pids/unicorn.pid`"
    end
    
    desc "Start webserver"
    task :start, :roles => :app do
      run "cd #{deploy_to} && bundle exec unicorn_rails -c config/unicorn.rb -E production -D"
    end
    
    desc "Block webserver"
    task :disable, :roles => :web do
      run "cd #{deploy_to} && touch public/maintenance.html"
    end
    
    desc "Start webserver"
    task :enable, :roles => :web do
      assets.glue_temp
      run "cd #{deploy_to} && rm -f public/maintenance.html"
      assets.deploy
    end
  end
  
  namespace :assets do
    desc "Create glued styles"
    task :glue, :roles => :app do
      assets.glue_temp
      assets.deploy
    end

    desc "Create glued styles in temp directory"
    task :glue_temp, :roles => :app do
      run "cd #{deploy_to} && RAILS_ENV=production bundle exec rake assets:glue"
    end

    desc "Deploy glued styles"
    task :deploy, :roles => :app do
      run "cd #{deploy_to} && RAILS_ENV=production bundle exec rake assets:install"
    end
  end  
  
  namespace :bundle do
    desc "Install & Update bundle"
    task :install, :roles => :app do
      run "cd #{deploy_to} && RAILS_ENV=production bundle install --quiet --binstubs --deployment --without development"
    end
  end
  
  namespace :resque do
    desc "Restart resque servers"
    task :restart, :roles => :resque do
      run "cd #{deploy_to} && RAILS_ENV=production RAILS_ROOT=#{deploy_to} god restart resque"
    end
    
    task :stop, :roles => :resque do
      run "cd #{deploy_to} && RAILS_ENV=production RAILS_ROOT=#{deploy_to} god stop resque"
    end

    task :start, :roles => :resque do
      run "cd #{deploy_to} && RAILS_ENV=production RAILS_ROOT=#{deploy_to} god start resque"
    end    
  end
end

# Dir[File.join(File.dirname(__FILE__), '..', 'vendor', 'gems', 'hoptoad_notifier-*')].each do |vendored_notifier|
#   $: << File.join(vendored_notifier, 'lib')
# end
# 
# require 'hoptoad_notifier/capistrano'

        require './config/boot'
        require 'airbrake/capistrano'
