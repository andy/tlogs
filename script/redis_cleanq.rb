#!/usr/bin/env script/console

# clean users queue
m = 500
$redis.keys('u:*:q').each do |k|
  c = $redis.zcard(k)
  next if c <= m
  
  $redis.zremrangebyrank k, 0, (c-m-1)
end

# clean neighborhood queue
m = 1000
$redis.keys('n:*').each do |k|
  c = $redis.zcard(k)
  next if c <= m
  
  $redis.zremrangebyrank k, 0, (c-m-1)
end