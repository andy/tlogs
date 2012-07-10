source "http://rubygems.org"

gem 'rails', '2.3.14'

gem 'whenever', :require => false

group :production do
  gem 'rpm_contrib'
  gem 'newrelic-redis'
  gem 'newrelic_rpm'
  gem 'hoptoad_notifier'
  gem 'unicorn', :require => false
end

# databases

gem 'mysql'

gem 'memcache-client', :require => 'memcache'

gem 'hiredis', '~> 0.4.0'
gem 'redis', '~> 2.2.0', :require => ["redis/connection/hiredis", "redis"]


# extra

gem 'mime-types'
gem 'rake'
gem 'rdoc'
gem 'system_timer'
gem 'will_paginate', '~> 2.3.16'
gem 'coderay'
gem 'ruby-openid', :require => 'openid'
gem 'hpricot'
gem 'russian'

gem 'json'


# search

gem 'thinking-sphinx', :require => 'thinking_sphinx'
gem 'ts-datetime-delta', '>= 1.0.0', :require => 'thinking_sphinx/deltas/datetime_delta'

gem 'savon', '0.7.9', :require => false


# image assets

gem 'mini_magick'
gem 'paperclip', '= 2.3.9'
gem 'paperclip-meta'


# templates

# gem 'therubyracer', :require => false
gem 'sass', :require => false
gem 'haml'
gem 'compass', :require => false
gem 'uglifier', :require => false

gem 'resque', '1.19.0'
gem 'resque-lock'

group :development do
	gem 'annotate'
end
