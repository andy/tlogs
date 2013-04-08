require 'rack/utils'

class FlashSessionCookieMiddleware
  def initialize(app, session_key = '_session_id')
    @app = app
    @session_key = session_key
  end

  def call(env)
    if env['HTTP_USER_AGENT'] =~ /^(Adobe|Shockwave) Flash/
      session = Rack::Request.new(env)[@session_key]
      env['HTTP_COOKIE'] = [ @session_key, session ].join('=').freeze unless session.nil?
    end
    @app.call(env)
  end
end
