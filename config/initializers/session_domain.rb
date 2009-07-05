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
        # turn "brendan.app.local:3000" to ".app.local"
        domain = @env['HTTP_HOST'].gsub(/:\d+$/, '').gsub(/^[^.]*/, '') unless @env['HTTP_HOST'] == 'localhost'
        @env['rack.session.options'] = @env['rack.session.options'].merge(:domain => domain) unless domain.blank?
      end
    end
  end
end
 
ActionController.send :include, ActionControllerExtensions