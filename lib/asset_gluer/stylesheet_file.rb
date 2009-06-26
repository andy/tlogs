require 'md5'

module AssetGluer
  # Файл стиля
  # Инициализируется абосолютным путем файла на файловой системе
  class StylesheetFile < AssetFile
    URL_REGEXP = /url\("?'?([^\)'"]*)'?"?\)/
    SRC_REGEXP = /src=["']?([^'",\)]+)['"]?/

    def self.dir
      ActionView::Helpers::AssetTagHelper::STYLESHEETS_DIR rescue "#{AssetGluer.asset_dir}/stylesheets"
    end    

    # преобразовать относительный путь в файле в абсолютный на
    # файловой системе
    def expand_relative_path(path)
      File.expand_path(File.join(@base_path, path))
    end

    # обработать строку импортирования css внутри css
    # то есть создать новый объект StylesheetFile и обработать
    # его обычным образом
    def import_line(line)
      return line unless line =~ /@import/
      css = line[/@import \(?"([^\)]+)"\)?;/, 1]
      if css =~ /http:\/\/assets?\./
        path = URI.parse(css).path.gsub(/^(\/\d+)\//, '/')
      else
        path = css
      end
      AssetGluer::StylesheetFile.new(expand_relative_path(css)).process
    end

    # преобразовать путь до картинки в относительный относительно AssetGluer.asset_dir
    # и проставить хост
    def modify_image_url(url)
      url = url.split("?").first
      path = expand_relative_path(url)
      image = url.start_with?("/") ? url : File.relative_to_dir(path, AssetGluer.asset_dir)
      path = AssetGluer.asset_dir + image
      if File.exists?(path)
        fstat = File.stat(path)
        stat = "/" + (Digest::MD5.hexdigest("#{fstat.size}").gsub(/[a-f]*/,'') + "0" * 10)[0,10]
      else
        stat = ""
      end
      url = "#{AssetGluer.assets_host(url)}#{stat}#{image}"
      url
    end

    # Читает содержимое файла, обрабатывает импорты и пути до изображений, возвращает результирующую строку
    def process
      File.open(@absolute_path).read.gsub(/\r\n/,"\n").split("\n").map do |line|
        if line =~ /@import/
          import_line(line)
        elsif line.index("url(") || line.index("src='")
          line.gsub!(URL_REGEXP) do |match|
            url = $1
            (url.start_with?("data:") || url.start_with?("#")) ? match : "url(#{modify_image_url(url)})"
          end
          line.gsub!(SRC_REGEXP) do |match|
            url = $1
            "src='#{modify_image_url(url)}'"
          end
          line
        else
          line
        end
      end.join("\n").gsub(/(\/\*[\s\S]*?\*\/)/, '')
    end
  end
end