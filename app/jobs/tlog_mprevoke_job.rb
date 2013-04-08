require 'resque/plugins/lock'

class TlogMprevokeJob
  extend Resque::Plugins::Lock

  @queue = :low

  def self.perform(user_id)
    user = User.find_by_id(user_id)

    user.mprevoke! if user
  end
end
