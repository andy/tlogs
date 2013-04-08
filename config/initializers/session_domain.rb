# http://gist.github.com/64874 for rack & rails 2.3

# Adjust sessions so they work across subdomains
# This also will work if your app runs on different TLDs
 
# from: http://szeryf.wordpress.com/2008/01/21/cookie-handling-in-multi-domain-applications-in-ruby-on-rails/
# modified to work with Rails 2.3.0
 
module ActionControllerExtensions
  def self.included(base)
    base::Dispatcher.send :include, DispatcherExtensions
  end
 
  module DispatcherExtensions
    def self.included(base)
      base.send :before_dispatch, :set_session_domain
    end
 
    def set_session_domain
      if @env['HTTP_HOST']
        current_service = Tlogs::Domains::CONFIGURATION.options_for @env['HTTP_HOST'], nil
        cookie_domain   = current_service.cookie_domain

        # check if they match (e.g. virtual host is known to us and we know how to deal with its cookies)
        if @env['HTTP_HOST'].gsub('.', '').ends_with?(cookie_domain.gsub('.', ''))        
          @env['rack.session.options'] = @env['rack.session.options'].merge(:domain => cookie_domain)
        end
      end
    end
  end
end
 
ActionController.send :include, ActionControllerExtensions