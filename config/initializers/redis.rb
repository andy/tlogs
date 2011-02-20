require 'redis'

begin
  redis_opts = YAML.load_file(File.join(RAILS_ROOT, 'config/redis.yml')).symbolize_keys!
rescue
  puts 'Redis configuration file (config/redis.yml) is missing'
  exit
end

$redis = Redis.new(redis_opts)
