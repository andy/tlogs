# Be sure to restart your web server when you modify this file.

RAILS_GEM_VERSION = '2.3.8' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
require File.join(File.dirname(__FILE__), '../lib/tlogs')

Rails::Initializer.run do |config|
  config.action_controller.session = { :key => Tlogs::SESSION.key, :secret => Tlogs::SESSION.secret }

  config.action_mailer.delivery_method = :sendmail
  config.action_mailer.default_charset = "utf-8"
  
  config.load_paths += %W( 
    #{RAILS_ROOT}/app/models/entries
    #{RAILS_ROOT}/lib/asset_gluer
  )

  config.to_prepare do
    Comment
    Entry
    User
  end
  
  config.gem 'image_science', :version => '>= 1.1.3'
  config.gem 'will_paginate', :version => '>= 2.2.2'
  config.gem 'coderay'
  config.gem 'ruby-openid', :lib => 'openid'
  config.gem 'memcache-client', :lib => 'memcache'
  config.gem 'hpricot'
  config.gem 'russian'
  config.gem 'redis', :version => '>= 2.0.0'

  config.gem 'thinking-sphinx',
    :lib => 'thinking_sphinx'

  config.gem 'ts-datetime-delta',
    :lib     => 'thinking_sphinx/deltas/datetime_delta',
    :version => '>= 1.0.0',
    :source  => 'http://gemcutter.org'

  config.gem 'mysql'
end
