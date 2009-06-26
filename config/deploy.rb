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
set :repository, 'git://github.com/andy/mmm-tasty.git'

# =============================================================================
# ROLES
# =============================================================================
# You can define any number of roles, each of which contains any number of
# machines. Roles might include such things as :web, or :app, or :db, defining
# what the purpose of each machine is. You can also specify options that can
# be used to single out a specific subset of boxes in a particular role, like
# :primary => true.

role :app, "mmm-tasty.ru", :primary => true
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
# =============================================================================
# OPTIONAL VARIABLES
# =============================================================================
set :deploy_to, '/home/tasty/mmm-tasty-git' # defaults to "/u/apps/#{application}"
set :user, 'tasty'            # defaults to the currently logged in user

# =============================================================================
# SSH OPTIONS
# =============================================================================
ssh_options[:user] = 'tasty'
ssh_options[:port] = 53040

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
    web.restart
    cache.flush
  end
  
  desc "Update sources, but do not restart server"
  task :light do
    git.pull
  end
  
  namespace :git do
    desc "Update sources from git"
    task :pull do
      run "cd #{deploy_to} && git pull"
    end
  end
  
  namespace :cache do
    desc "Flush memcache"
    task :flush do
      run "echo flush_all | nc -q 1 localhost 11211"
    end
  end
  
  namespace :web do
    desc "Restart webserver"
    task :restart do
      assets.glue_temp
      run "cd #{deploy_to} && thin -C config/thin.yml restart"
      assets.deploy
    end
    
    desc "Stop webserver"
    task :stop do
      run "cd #{deploy_to} && thin -C config/thin.yml stop"
    end
    
    desc "Start webserver"
    task :start do
      assets.glue_temp
      run "cd #{deploy_to} && thin -C config/thin.yml start"
      assets.deploy
    end
  end
  
  namespace :assets do
    desc "Create glued styles"
    task :glue do
      assets.glue_temp
      assets.deploy
    end

    desc "Create glued styles in temp directory"
    task :glue_temp do
      run "cd #{deploy_to} && RAILS_ENV=#{stage} rake assets:glue"
    end

    desc "Deploy glued styles"
    task :deploy do
      run "cd #{deploy_to} && rm -f public/stylesheets/cache/*.css public/javascripts/cache/*.js"
      run "cp #{deploy_to}/public/stylesheets/cache-tmp/* #{deploy_to}/public/stylesheets/cache/"
      run "cp #{deploy_to}/public/javascripts/cache-tmp/* #{deploy_to}/public/javascripts/cache/"
    end
  end  
end