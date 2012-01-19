class Entry
  ## hooks
  after_create :try_watchers_update


  ## class methods
  def self.enqueue_key
    "e:ping"
  end


  ## public methods
  def watcher_ids
    @watcher_ids ||= build_watcher_ids    
  end
  
  def build_watcher_ids
    ids = [
      # author himself
      self.author.id,

      # tier1 - entry subscribers
      self.subscriber_ids,
    
      # tier2 - user subscribers
      self.author.listed_me_as_all_friend_light_ids,
      
      # tier3 - users who positevely voted for this entry
      # self.votes.positive.map(&:user_id)
    ].flatten.compact.uniq
    
    # respect user's privacy settings
    case self.author.tlog_settings.privacy
    when 'open'
      ids
      
    when 'rr'
      ids
      
    when 'fr'
      (ids & self.author.all_friend_ids) << self.author.id
      
    when 'me'
      [self.author.id]
      
    end    
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

    true
  end
  
  def try_insert_watcher(user_id)
    self.insert_watcher(user_id) if self.watchable?
  end
  
  def try_remove_watcher(user_id)
    self.remove_watcher(user_id)
  end
  
  def try_watchers_destroy
    self.destroy_watchers
    # or method 2 - disabled
    # self.enqueue_destroy_watchers
    
    true
  end

  ## protected
  protected
    # update each personal queue with interested peers
    def update_watchers
      # logger.debug "e #{self.id}/#{self.author.id} u#{self.watcher_ids.inspect} n#{User::neighborhood_queue_key(self.author.id)}"

      # enqueue for all watchers ...
      $redis.multi do
        # push this to every watcher personally
        
        self.watcher_ids.each do |user_id|
          $redis.zadd(User::personal_queue_key(user_id), self.updated_at.to_i, self.id)
        end
      
        # push this as a key to all neighbors sharing same h00d
        # BUT update this entry only if marked as mainpageable - all non public entries pop up only
        $redis.zadd(User::neighborhood_queue_key(self.author.id), self.updated_at.to_i, self.id) if self.is_mainpageable?
      end
    end
    
    def insert_watcher(user_id)
      $redis.zadd(User::personal_queue_key(user_id), self.updated_at.to_i, self.id)
    end
    
    def remove_watcher(user_id)
      $redis.zrem(User::personal_queue_key(user_id), self.id)
    end
  
    # remove entry from all queues where it could have been enqueued
    def destroy_watchers
      $redis.multi do
        self.watcher_ids.each do |user_id|
          $redis.zrem(User::personal_queue_key(user_id), self.id)
        end
      
        $redis.zrem(User::neighborhood_queue_key(self.author.id), self.id)
      end
    end

    # enqueue update rather than performing it instantly
    def enqueue_watchers_update
      $redis.zadd(Entry::enqueue_key, self.updated_at.to_i, self.id)
    end
end