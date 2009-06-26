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
      asset_id = file_mtime("#{RAILS_ROOT}/public#{path}")
      prefix = asset_id ? "/#{asset_id}" : ""
      "#{prefix}#{path}"
    end

    def file_mtime(source)
      if File.exists?(source)
        fstat = File.stat(source)
        (Digest::MD5.hexdigest("#{fstat.size}").gsub(/[a-f]*/,'')+"0"*10)[0,10]
      else
        nil
      end
    end
end
