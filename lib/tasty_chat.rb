class TastyChat
  attr_accessor :user, :redis

  def initialize options
    options.assert_valid_keys(:user, :redis)

    @user   = options[:user]
    @redis  = options[:redis]
  end
  
  def channel name
    TastyChatChannel.new self, name
  end

  #
  # Subscriptions
  #
  
  def recent
    channels.map(&:recent)
  end

  def channels
    @redis.smembers(subs_key).map { |name| channel(name) }
  end
  
  def subs_key
    ['chat', 'subs', @user.id].join(':')
  end

  def counter_key
    ['chat', 'counters'].join(':')
  end
  
  #
  # Class methods
  #
  def self.for options
    self.new options
  end
end

class TastyChatChannel
  attr_accessor :name

  def initialize chat, name
    @chat = chat
    @name = name || 'Лепрозорий'
  end
  
  def uuid
    Digest::SHA1.hexdigest(@name)[0..8]
  end


  def subscribe!
    @chat.redis.sadd @chat.subs_key, @name
  end
  
  def unsubscribe!
    @chat.redis.srem @chat.subs_key, @name
  end
  
  def subscribed?
    @chat.redis.sismember @chat.subs_key, @name
  end
  
  def post text
    subscribe! unless subscribed?

    message     = { :id      => gen_message_id!,
                    :stamp   => Time.now.to_i,
                    :text    => text,
                    :user    => @chat.user.id
                  }

    count = @chat.redis.lpush channel_key, Base64.encode64(Marshal.dump(message))
    
    # truncage channel if it gets too long
    @chat.redis.ltrim(channel_key, 0, 1000) if count > 1000
  end
  
  def recent(count = 20)
    @chat.redis.lrange(channel_key, 0, count).map { |message| Marshal.load(Base64.decode64(message)) }
  end
  
  def channel_key
    ['chat', 'chan', @name].join(':')
  end

  def gen_message_id!
    @chat.redis.hincrby @chat.counter_key, @name, 1
  end
  
  def cur_message_id
    @chat.redis.hget @chat.counter_key, @name
  end
end
