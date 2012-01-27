# encoding: utf-8
class User
  
  ## class methods
  def self.personal_queue_key(user_id)
    "u:#{user_id}:q"
  end
  
  def self.neighborhood_queue_key(user_id)
    "n:#{user_id.to_i / 5000}"
  end
  
  def self.queue_key(user_id)
    "q:#{user_id}"
  end
  
  ## public methods
  def personal_queue_key
    User::personal_queue_key(self.id)
  end
  
  def neighborhood_queue_key
    User::neighborhood_queue_key(self.id)
  end
  
  def queue_key
    User::queue_key(self.id)
  end
  
  def update_entries_queue
    # unite neighborhood & personal queue
    count = $redis.zunionstore(self.queue_key, [self.personal_queue_key, self.neighborhood_queue_key], :aggregate => 'max')
    
    count
  end    
  
  def entries_queue(offset = 0, limit = 42)
    self.update_entries_queue

    # fetch the page
    $redis.zrevrange(self.queue_key, offset, offset + limit - 1).map(&:to_i)
  end
  
  def entries_queue_length
    self.update_entries_queue

    $redis.zcard(self.queue_key)
  end
  
  # personal queue
  def my_entries_queue(offset = 0, limit = 42)
    $redis.zrevrange(self.personal_queue_key, offset, offset + limit - 1).map(&:to_i)
  end
  
  def my_entries_queue_length
    $redis.zcard(self.personal_queue_key)
  end
end
