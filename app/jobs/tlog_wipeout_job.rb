require 'resque/plugins/lock'

class TlogWipeoutJob
  extend Resque::Plugins::Lock

  @queue = :low

  def self.perform(user_id)
    user = User.find_by_id(user_id)

    user.wipeout! if user
  end
end
