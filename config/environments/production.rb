# Settings specified here will take precedence over those in config/environment.rb
# config.threadsafe!

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
config.action_view.cache_template_loading            = true

# Logging
config.log_level = :info

# Caching, woohoo!
config.cache_store = :mem_cache_store, ['f1.tlogs.ru:11211', 'f2.tlogs.ru:11211'], { :namespace => 'p', :no_reply => true, :timeout => nil, :autofix_keys => true }

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = Proc.new { |source, request| "http://assets#{source.hash % 4}.#{request.current_service.host}" }
config.action_controller.asset_host                 = "http://assets%d.mmm-tasty.ru"

# Email delivery
config.action_mailer.delivery_method = :sendmail
config.action_mailer.default_charset = "utf-8"
# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false
# config.action_mailer.delivery_method = :smtp
# config.action_mailer.smtp_settings = {
#   :tls => true,
#   :address => "smtp.gmail.com",
#   :port => "587",
#   :domain => "mmm-tasty.ru",
#   :authentication => :plain,
#   :user_name => "noreply@mmm-tasty.ru",
#   :password => "keepquiet"
# }
