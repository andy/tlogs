require 'rack'
require 'net/http'

module Rack
  class AssetProxy
    def initialize(app, options = {})
      @app          = app
      @asset_path   = options[:asset_path] || Regexp.new(/^\/assets\//)
      @asset_url    = options[:asset_uri]
    end
    
    def call(env)
      if env['PATH_INFO'].match(@asset_path)
        logger = RAILS_DEFAULT_LOGGER

        uri = URI.parse(@asset_url + env['PATH_INFO'])
        
        logger.debug "AssetProxy: fetching #{uri.to_s}"
        res = Net::HTTP.get_response(uri)
        
        # save file on success
        if res.is_a?(Net::HTTPSuccess)
          local = ::File.join(Rails.public_path, uri.path)
          FileUtils.mkdir_p(::File.dirname(local)) unless ::File.exist?(::File.dirname(local))
          ::File.open(local, 'w') { |file| file.write res.body } unless ::File.exist?(local)
        else
          RAILS_DEFAULT_LOGGER.debug "AssetProxy: error fetching #{uri.to_s}: #{res.code} (#{res.content_type})"
        end

        [res.code, { 'Content-type' => res.content_type }, res.body]
      else
        @app.call(env)
      end
    end
  end
end