# Be sure to restart your web server when you modify this file.

RAILS_GEM_VERSION = '2.3.14' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
require File.join(File.dirname(__FILE__), '../lib/tlogs')

Rails::Initializer.run do |config|
  config.action_controller.session = { :expire_after => 315576000, :key => Tlogs::SESSION.key, :secret => Tlogs::SESSION.secret }

  config.autoload_paths += %W( 
    #{RAILS_ROOT}/app/models/entries
    #{RAILS_ROOT}/app/models/billing
    #{RAILS_ROOT}/app/jobs
    #{RAILS_ROOT}/lib/asset_gluer
  )

  config.to_prepare do
    Comment
    Entry
    User
  end  
end
