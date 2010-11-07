class User
  def self.entries_queue_key(user_id)
    "u:#{user_id}:q"
  end
  
  def entries_queue_key
    User::entries_queue_key(self.id)
  end
  
  def entries_queue(offset = 0, limit = 42)
    $redis.zrevrange(self.entries_queue_key, offset, offset + limit).map(&:to_i)
  end
  
  def entries_queue_length
    $redis.zcard(self.entries_queue_key)
  end
end