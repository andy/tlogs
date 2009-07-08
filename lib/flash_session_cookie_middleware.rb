require 'rack/utils'

class FlashSessionCookieMiddleware
  def initialize(app, session_key = '_session_id')
    @app = app
    @session_key = session_key
  end

  def call(env)
    if env['HTTP_USER_AGENT'] =~ /^(Adobe|Shockwave) Flash/
      if env['REQUEST_METHOD'] == 'POST'
        session = env['rack.request.form_hash'][@session_key]
      elsif env['REQUEST_METHOD'] == 'GET'
        params = ::Rack::Utils.parse_query(env['QUERY_STRING'])
        session = params[@session_key] unless params[@session_key].nil?
      end
      env['HTTP_COOKIE'] = [ @session_key, session ].join('=').freeze unless session.nil?
    end
    @app.call(env)
  end
end