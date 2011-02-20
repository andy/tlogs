# Configuration for Unicorn (not Rack)
#
# See http://unicorn.bogomips.org/Unicorn/Configurator.html for complete documentation
#
# Taken from http://github.com/blog/517-unicorn
#

rails_env = ENV['RAILS_ENV'] || 'production'

rails_root = Dir.pwd

begin
  unicorn_opts = YAML.load_file(File.join(rails_root, 'config/unicorn.yml'))
rescue
  puts 'Unicorn configuration file (config/unicorn.yml) is missing'
  exit
end

wpc = rails_env == 'production' ? unicorn_opts['worker_processes'] : 2

worker_processes wpc

listen File.join(rails_root, 'tmp/sockets/unicorn.sock'), :backlog => unicorn_opts['backlog']

timeout 30

stderr_path File.join(rails_root, 'log/unicorn.stderr.log')
stdout_path File.join(rails_root, 'log/unicorn.stdout.log')

# combine REE with "preload_app true" for memory savings
# http://rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
preload_app true

if GC.respond_to?(:copy_on_write_friendly=)
  GC.copy_on_write_friendly = true
end


before_fork do |server, worker|
  # the following is highly recomended for Rails + "preload_app true"
  # as there's no need for the master process to hold a connection
  ActiveRecord::Base.connection.disconnect!

  old_pid = RAILS_ROOT + '/tmp/pids/unicorn.pid.oldbin'
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end  
end

after_fork do |server, worker|
  # the following is *required* for Rails + "preload_app true",
  ActiveRecord::Base.establish_connection
end

