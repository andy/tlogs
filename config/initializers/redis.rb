require 'redis'

$redis = Redis.new(:thread_safe => true)
