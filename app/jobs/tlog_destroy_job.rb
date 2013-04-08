require 'resque/plugins/lock'

class TlogDestroyJob
  extend Resque::Plugins::Lock

  @queue = :low
  
  def self.perform(user_id)
    user = User.find_by_id(user_id)
    
    user.destroy if user
  end
end