class Entry
  ## hooks
  after_create :try_watchers_update
  
  after_destroy :try_watchers_destroy


  ## class methods
  def self.enqueue_key
    "e:q"
  end


  ## public methods
  def watcher_ids
    [
      # author himself
      self.author.id,

      # tier1 - entry subscribers
      self.subscriber_ids,
    
      # tier2 - user subscribers
      self.author.listed_me_as_all_friend_light_ids      
    ].flatten.compact.uniq
  end
  
  # update each personal queue with interested peers
  def update_watchers
    # enqueue for all watchers ...
    $redis.multi do
      # push this to every watcher personally
      self.watcher_ids.each do |user_id|
        $redis.zadd(User::entries_queue_key(user_id), self.updated_at.to_i, self.id)
      end
      
      # push this as a key to all neighbors sharing same h00d
      # BUT update this entry only if marked as mainpageable - all non public entries pop up only
      $redis.zadd(User::neighborhood_queue_key(user_id), self.updated_at.to_i, self.id) if self.is_mainpageable?
    end
  end
  
  # remove entry from all queues where it could have been enqueued
  def destroy_watchers
    $redis.multi do
      self.watcher_ids.each do |user_id|
        $redis.zrem(User::entries_queue_key(user_id), self.id)
      end
      
      $redis.zrem(User::neighborhood_queue_key(user_id), self.id)
    end
  end

  # enqueue update rather than performing it instantly
  def enqueue_watchers_update
    $redis.zadd(Entry::enqueue_key, self.updated_at.to_i, self.id)
  end

  # is this entry even WATCHABLE? must be public and not anonymous
  def watchable?
    !self.is_private? && self.type != 'AnonymousEntry'
  end

  ## callbacks
  def try_watchers_update
    if self.watchable?
      # method 1
      self.update_watchers
      # OR method 2 - disabled
      # self.enqueue_watchers_update
    end
  end
  
  def try_watchers_destroy
    self.destroy_watchers
    # or method 2 - disabled
    # self.enqueue_destroy_watchers
  end
  
end