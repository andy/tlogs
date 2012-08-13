$asset_files_checksum_cache = {}

module ActionView::Helpers::AssetTagHelper  
  def asset_file_path
    File.join(ASSETS_DIR, public_path[/^\/[0-9]{10}\/(.*)$/, 1] || public_path)
  end
  
  protected
    def rewrite_asset_path path
      full_path = "#{Rails.root}/public#{path}"
      if should_cache?(full_path)
        asset_id  = file_mtime(full_path)
        prefix    = asset_id ? "/#{asset_id}" : ""
        "#{prefix}#{path}"
      else
        path
      end
    end

    def should_cache? source
      !source.starts_with? "#{Rails.root}/public/assets"
    end

    def file_mtime source
      return $asset_files_checksum_cache[source] if $asset_files_checksum_cache.keys.include?(source)
      
      result  = nil
      fstat   = File.stat(source) rescue nil
      result  = (Digest::MD5.hexdigest("#{fstat.size}").gsub(/[a-f]*/,'')+"0"*10)[0,10] if fstat
      
      $asset_files_checksum_cache[source] = result
      
      result
    end
end
