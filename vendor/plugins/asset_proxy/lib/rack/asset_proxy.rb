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
      logger = RAILS_DEFAULT_LOGGER

      if env['PATH_INFO'].match(@asset_path)
        uri = URI.parse(@asset_url + env['PATH_INFO'])
        
        # Verify that asset negative reply is stored in cache
        cache_key = ['assetproxy', 'cache', Digest::SHA1.hexdigest(uri.to_s)].join(':')
        cached_reply = Rails.cache.read(cache_key)
        return cached_reply unless cached_reply.nil?

        logger.debug "AssetProxy: fetching #{uri.to_s}"
        
        res = Net::HTTP.get_response(uri)
        
        # save file on success
        if res.is_a?(Net::HTTPSuccess)
          local = ::File.join(Rails.public_path, uri.path)
          FileUtils.mkdir_p(::File.dirname(local)) unless ::File.exist?(::File.dirname(local))
          ::File.open(local, 'w') { |file| file.write res.body } unless ::File.exist?(local)
        else
          Rails.cache.write(cache_key, [res.code, { 'Content-type' => res.content_type}, res.body], :expires_in => 1.week)
          logger.debug "AssetProxy: error fetching #{uri.to_s}: #{res.code} (#{res.content_type})"
        end

        [res.code, { 'Content-type' => res.content_type }, res.body]
      else
        @app.call(env)
      end
    end
  end
end