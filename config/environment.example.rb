# Be sure to restart your web server when you modify this file.

RAILS_GEM_VERSION = '2.2.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
require File.join(File.dirname(__FILE__), '../lib/tlogs')

Rails::Initializer.run do |config|
  config.action_controller.session = { :session_key => Tlogs::SESSION_CONFIGURATION.key, :secret => Tlogs::SESSION_CONFIGURATION.secret }

  config.action_mailer.delivery_method = :sendmail
  config.action_mailer.default_charset = "utf-8"
  
  config.gem 'image_science', :version => '>= 1.1.3'
  config.gem 'will_paginate', :version => '>= 2.2.2'
  config.gem 'coderay'
  config.gem 'sqlite3-ruby', :lib => 'sqlite3'
  config.gem 'ruby-openid', :lib => 'openid'
  config.gem 'memcache-client', :lib => 'memcache'
  config.gem 'hpricot'
  
  # if you plan on using mysql, uncomment this
  config.gem 'mysql'
end