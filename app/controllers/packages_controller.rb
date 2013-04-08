class PackagesController < ApplicationController
  skip_before_filter :preload_is_private
  skip_before_filter :preload_current_service
  skip_before_filter :preload_current_site
  skip_before_filter :preload_current_user

  
  def css
    files     = TASTY_ASSETS[:stylesheets][params[:name]]
    key       = files.map { |f| Digest::SHA1.file(f).hexdigest }.join(':')
    cache_key = ['pack', 'css', Digest::SHA1.hexdigest(key)].join(':')
    result    = Rails.cache.fetch(cache_key, :expires_in => 1.day) { AssetGluer::StylesheetFile.glue(files) }

    render :text => result, :content_type => 'text/css'
  end
  
  def js
    files     = TASTY_ASSETS[:javascripts][params[:name]]
    key       = files.map { |f| Digest::SHA1.file(f).hexdigest }.join(':')
    cache_key = ['pack', 'js', Digest::SHA1.hexdigest(key)].join(':')
    result    = Rails.cache.fetch(cache_key, :expires_in => 1.day) { AssetGluer::JavascriptFile.glue(files) }

    render :text => result, :content_type => 'text/javascript'
  end
end