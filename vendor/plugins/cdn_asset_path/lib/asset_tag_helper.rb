$asset_files_checksum_cache = {}

module ActionView::Helpers::AssetTagHelper  
  def asset_file_path
    File.join(ASSETS_DIR, public_path[/^\/[0-9]{10}\/(.*)$/, 1] || public_path)
  end
  
  protected
    def rewrite_asset_path path
      asset_id  = file_mtime "#{Rails.root}/public#{path}"
      prefix    = asset_id ? "/#{asset_id}" : ""
      "#{prefix}#{path}"
    end

    def should_cache? source
      !source.starts_with? "#{Rails.root}/public/assets"
    end

    def file_mtime source
      return $asset_files_checksum_cache[source] if should_cache?(source) && $asset_files_checksum_cache.keys.include?(source)
      
      result  = nil
      fstat   = File.stat(source) rescue nil
      result  = (Digest::MD5.hexdigest("#{fstat.size}").gsub(/[a-f]*/,'')+"0"*10)[0,10] if fstat
      
      $asset_files_checksum_cache[source] = result if should_cache?(source)
      
      result
    end
end
