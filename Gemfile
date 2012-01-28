source 'https://rubygems.org'

gem 'rails', '3.2.1'

group :development do
	gem 'annotate'
	gem 'capistrano'
end

group :test, :development do
  gem "rspec-rails", "~> 2.4"
  gem 'factory_girl_rails'
end

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
end

group :production do
  gem 'unicorn'
  gem 'airbrake'
end

#
# Databases & Storage clients
#
gem 'mysql2'

gem 'hiredis', '~> 0.4.0'
gem 'redis', '>= 2.2.0', :require => ["redis/connection/hiredis", "redis"]

gem 'memcache-client'

gem 'resque'
gem 'resque-lock'


#
# Authentication & Authorization
#
gem 'devise'
gem 'omniauth-openid'
gem 'omniauth-google-oauth2' # https://code.google.com/apis/console/
gem 'omniauth-mailru' # http://api.mail.ru/docs/guides/oauth/
gem 'omniauth-yandex' # https://oauth.yandex.ru/client/new


#
# View helpers
#
gem 'jquery-rails'
gem 'coderay'
gem 'hpricot'



#
# ActiveRecord extensions
#
gem 'acts_as_list'
gem 'acts-as-taggable-on', '~> 2.2.2'

gem 'mini_magick'
gem 'paperclip', '~> 2.0'
gem 'paperclip-meta'

gem 'will_paginate'

gem 'thinking-sphinx'


#
# Configuration helpers
#
gem 'settingslogic'


#
# Console stuff
#
gem 'whenever', :require => false

