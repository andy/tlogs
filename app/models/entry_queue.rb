#
# r = Redis.new :host => $redis.client.host, :port => $redis.client.port, :logger => Logger.new(STDOUT)
# q = EntryQueue.new 'test', :redis => r, :queue_limit => 7, :queue_step => 3, :per_page => 3
#
#
# > q = EntryQueue.new 'live'
# > q.push(@entry, Time.now)
# ...
#
# > q.up(@entry)
#
# > q.items(:page => 1)
# > q.items(:at => @entry.id, :per_page => 15)
#
# > q.pop(@entry)
#

class EntryQueue
  QUEUE_LIMIT = 2000
  QUEUE_STEP  = 0.01
  PER_PAGE    = 15

  def initialize(name, options = {})
    options       = options.dup || {}

    @name         = name
    @redis        = options.fetch(:redis, $redis)
    @queue_limit  = options.fetch(:queue_limit, QUEUE_LIMIT)
    @queue_step   = options.fetch(:queue_step, (@queue_limit * QUEUE_STEP).floor)
    @per_page     = options.fetch(:per_page, PER_PAGE)
  end
  
  def key(postfix = nil)
    ['eq', @name, postfix].compact.join(':')
  end
  
  def push(id)
    @redis.zadd key, id, id
    
    @redis.zremrangebyrank(key, 0, -length_limit) if length > length_limit
  end
  
  def delete(id)
    @redis.zrem key, id
  end
  
  def toggle(id, should_present = nil)
    should_present = !exists?(id) if should_present.nil?
    should_present ? push(id) : delete(id)
  end
  
  def items(start, per_page = nil)
    per_page ||= @per_page
    @redis.zrevrange(key, start, start + per_page - 1).map(&:to_i)
  end
  
  def page(num, per_page = nil)
    per_page ||= @per_page
    num        = 1 if num <= 1
    items (num - 1) * per_page, per_page
  end
  
  def after(id, per_page = nil)
    per_page  ||= @per_page

    if offset = @redis.zrevrank(key, id)
      items(offset + 1, per_page)
    else
      @redis.zrevrangebyscore(key, "(#{id}", '-inf', :limit => [0, per_page]).map(&:to_i)
    end
  end
  
  def exists?(id)
    !!@redis.zrank(key, id)
  end
  
  def length
    @redis.zcard key
  end
  
  def length_limit
    @queue_limit + @queue_step
  end
end