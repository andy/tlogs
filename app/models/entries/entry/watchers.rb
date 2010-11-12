class Entry
  after_create :try_watchers_update

  def self.enqueue_key
    "e:q"
  end

  def watcher_ids
    [
      # author himself
      self.author.id,

      # tier1 - entry subscribers
      self.subscriber_ids,
    
      # tier2 - user subscribers
      self.author.listed_me_as_all_friend_light_ids,
      
      # tier3 - neighbors
      # how to ?
    ].flatten.compact.uniq
  end
  
  # update each personal queue with interested peers
  def update_watchers
    # enqueue for all watchers ...
    $redis.multi do
      self.watcher_ids.each { |user_id| $redis.zadd(User::entries_queue_key(user_id), self.updated_at.to_i, self.id) }
    end    
  end

  # enqueue update rather than performing it instantly
  def enqueue_watchers_update
    $redis.zadd(Entry::enqueue_key, self.updated_at.to_i, self.id)
  end

  def try_watchers_update
    if self.watchable?
      # method 1
      self.update_watchers
      # OR method 2 - disabled
      # self.enqueue_watchers_update
    end
  end
  
  # is this entry even WATCHABLE? must be public and not anonymous
  def watchable?
    !self.is_private? && self.type != 'AnonymousEntry'
  end
end