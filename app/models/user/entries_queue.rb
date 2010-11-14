class User
  
  ## class methods
  def self.entries_queue_key(user_id)
    "u:#{user_id}:q"
  end
  
  def self.neighborhood_queue_key(user_id)
    "n:#{user_id.to_i / 500}"
  end
  
  ## public methods
  def entries_queue_key
    User::entries_queue_key(self.id)
  end
  
  def neighborhood_queue_key
    User::neighborhood_queue_key(self.id)
  end
  
  def entries_queue(offset = 0, limit = 42)
    eqk = "q:#{self.id}"
    
    # unite neighborhood & personal queue
    $redis.zunionstore(eqk, [self.entries_queue_key, self.neighborhood_queue_key], :aggregate => 'max')
    
    # fetch the page
    $redis.zrevrange(eqk, offset, offset + limit - 1).map(&:to_i)
  end
  
  def entries_queue_length
    $redis.zcard(self.entries_queue_key)
  end
end
