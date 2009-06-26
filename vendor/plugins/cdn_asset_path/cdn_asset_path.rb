if defined?(Mongrel)
  class Mongrel::DirHandler
    ASSET_REGEXP = /^\/[0-9]{10}\/(.*)$/
    alias_method :can_serve_without_rewrite, :can_serve
    def can_serve(path_info)
      can_serve_without_rewrite(path_info[ASSET_REGEXP, 1] || path_info)
    end
  end
end

module ActionView::Helpers::AssetTagHelper
  def asset_file_path
    File.join(ASSETS_DIR, public_path[/^\/[0-9]{10}\/(.*)$/, 1] || public_path)
  end
  
  protected
    def rewrite_asset_path(path)
      return path if skip_versioning?(path)
      asset_id = file_mtime("#{RAILS_ROOT}/public#{path}")
      prefix = asset_id ? "/#{asset_id}" : ""
      "#{prefix}#{path}"
    end

    def skip_versioning?(path)
      # return true if path.index("/assets")
      false
    end

    def file_mtime(source)
      if File.exists?(source)
        fstat = File.stat(source)
        (Digest::MD5.hexdigest("#{fstat.size}").gsub(/[a-f]*/,'')+"0"*10)[0,10]
      # support for ncss
      elsif source.ends_with?('.css')
        ncss_path = File.join(RAILS_ROOT, 'app', 'views', 'stylesheets', File.basename(source).sub('.css', '.ncss'))
        if File.exists?(ncss_path)
          fstat = File.stat(ncss_path)
          (Digest::MD5.hexdigest("#{fstat.size}").gsub(/[a-f]*/,'')+"0"*10)[0,10]          
        else
          nil
        end
      else
        nil
      end
    end
end if RAILS_ENV == 'production'
