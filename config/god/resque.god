rails_env   = ENV['RAILS_ENV']  || 'development'
rails_root  = ENV['RAILS_ROOT'] || '/home/tlogs-git/tasty'
num_workers = rails_env == 'production' ? 5 : 2

num_workers.times do |num|
  God.watch do |w|
    w.log      = 'log/god.log'
    w.name     = "resque-#{num}"
    w.group   = 'resque'
    w.interval = 30.seconds
    w.env      = {"QUEUE"=>"critical,high,low", "RAILS_ENV"=>rails_env}
    w.start    = "cd #{rails_root} && bin/bundle exec rake environment resque:work"
    w.dir      = rails_root
    
    w.stop_signal   = 'QUIT'
    w.stop_timeout  = 1.minute

    if rails_env == 'production'
      w.uid   = 'tasty'
      w.gid   = 'tasty'
    end

    # retart if memory gets too high
    w.transition(:up, :restart) do |on|
      on.condition(:memory_usage) do |c|
        c.above = 350.megabytes
        c.times = 2
      end
    end

    # determine the state on startup
    w.transition(:init, { true => :up, false => :start }) do |on|
      on.condition(:process_running) do |c|
        c.running = true
      end
    end

    # determine when process has finished starting
    w.transition([:start, :restart], :up) do |on|
      on.condition(:process_running) do |c|
        c.running = true
        c.interval = 5.seconds
      end

      # failsafe
      on.condition(:tries) do |c|
        c.times = 5
        c.transition = :start
        c.interval = 5.seconds
      end
    end

    # start if process is not running
    w.transition(:up, :start) do |on|
      on.condition(:process_running) do |c|
        c.running = false
      end
    end
  end
end