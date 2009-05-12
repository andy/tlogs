module Delayed
  module MessageSending
    def send_later(method, *args)
      if false && RAILS_ENV == "development"
        if !Delayed::Worker.alive?
          Delayed::Worker.daemonize 
          ActiveRecord::Base.establish_connection
        end
      end
      return send(method, *args) if RAILS_ENV == "test"
      Delayed::Job.enqueue Delayed::PerformableMethod.new(self, method.to_sym, args)
    end
    
    def send_later_in(delay, method, *args)
      if false && RAILS_ENV == "development"
        if !Delayed::Worker.alive?
          Delayed::Worker.daemonize 
          ActiveRecord::Base.establish_connection
        end
      end
      return send(method, *args) if RAILS_ENV == "test"
      Delayed::Job.enqueue Delayed::PerformableMethod.new(self, method.to_sym, args), :run_at => (Delayed::Job.db_time_now + delay)
    end
  end
end