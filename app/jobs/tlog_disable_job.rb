require 'resque/plugins/lock'

class TlogDisableJob
  extend Resque::Plugins::Lock

  @queue = :low

  def self.perform(user_id)
    user = User.find_by_id(user_id)

    user.disable! if user
  end
end
