module Rack
  class AssetPath
    ASSET_REGEXP = /^\/[0-9]{10}(\/.*)$/

    def initialize(app)
      @app = app
    end
  
    def call(env)
      env['PATH_INFO'] = env['PATH_INFO'][ASSET_REGEXP, 1] || env['PATH_INFO']

      @app.call(env)
    end
  end
end