require 'md5'

module AssetGluer
  # Файл стиля
  # Инициализируется абосолютным путем файла на файловой системе
  class StylesheetFile < AssetFile
    URL_REGEXP = /url\("?'?([^\)'"]*)'?"?\)/
    SRC_REGEXP = /src=["']?([^'",\)]+)['"]?/

    def self.dir
      File.join(AssetGluer.asset_dir, 'stylesheets')
    end    

    # преобразовать относительный путь в файле в абсолютный на
    # файловой системе
    def expand_relative_path(path)
      File.expand_path(File.join(Rails.public_path, path))
    end

    # Читает содержимое файла, обрабатывает импорты и пути до изображений, возвращает результирующую строку
    def process
      contents = File.read(@absolute_path)

      contents.gsub!("\r\n", "\n")

      # process with sass
      contents = filter_with_sass(contents) if %w(.scss .sass).include?(File.extname(@absolute_path))
      
      # process images
      contents = filter_images(contents)
      
      contents
    end
    
    def self.process(contents)
      contents
    end
    
    protected
      def filter_with_sass(contents, options = {})
        require 'sass'

        default_sass_options = {
          :syntax       => File.extname(@absolute_path)[1..-1].to_sym,
          :style        => Rails.env.production? ? :compressed : :expanded,
          :line_numbers => Rails.env.development? 
        }
        engine = Sass::Engine.new(contents, default_sass_options.merge(options))
        
        engine.render
      end

      def filter_images(contents)
        contents.split("\n").map do |line|
          if line.index("url(") || line.index("src='")
            line.gsub!(URL_REGEXP) do |match|
              url = $1
              (url.start_with?("data:") || url.start_with?("#")) ? match : "url(#{assetify_image_url(url)})"
            end
            line.gsub!(SRC_REGEXP) do |match|
              url = $1
              "src='#{assetify_image_url(url)}'"
            end
            line
          else
            line
          end
        end.join("\n")
      end
    
      # преобразовать путь до картинки в относительный относительно AssetGluer.asset_dir
      # и проставить хост
      def assetify_image_url(url)
        url   = url.split("?").first
        path  = expand_relative_path(url)
        image = url.start_with?("/") ? url : File.relative_to_dir(path, AssetGluer.asset_dir)
        path  = AssetGluer.asset_dir + image

        if File.exists?(path)
          fstat = File.stat(path)
          stat = "/" + (Digest::MD5.hexdigest("#{fstat.size}").gsub(/[a-f]*/,'') + "0" * 10)[0,10]
        else
          stat = ""
        end
        "#{AssetGluer.assets_host(url)}#{stat}#{image}"
      end
    
  end
end