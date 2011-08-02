module AssetGluer
  def self.assets_host(file_name)
    pattern = ActionController::Base.asset_host rescue "http://assets%d.mmm-tasty.ru"
    pattern % (file_name.to_s.hash % 4)
  end

  # Публичная папка проекта
  # Относительно нее будут переименовываться пути до изображений в файлах стилей
  def self.asset_dir
    ActionView::Helpers::AssetTagHelper::ASSETS_DIR rescue File.join(Dir.pwd, "public")
  end

  class AssetFile
    def initialize(path)
      @absolute_path = File.join(Rails.root, path)
      # @absolute_path.gsub!(/\/cache/, "") if RAILS_ENV == "development" && ActionController::Base.perform_caching
      @base_path = File.dirname(@absolute_path)
    end

    def self.glue(*paths)
      options = paths.extract_options!

      contents = paths.flatten.map { |path| self.new(path).process }.join("\n")
      
      self.process(contents)
    end
    
    def self.cache_dir
      File.join(self.dir, "cache")
    end

    def self.temp_cache_dir
      File.join(self.dir, "cache-tmp")
    end
  end
end

class File
  # урезает абсолюнтый путь до файла до относительного,
  # относительно папки dirname (учитывается первое упоминание папки в пути)
  # File.relative_to_dir("/home/longman/trash", "longman") => "/trash"
  # Используется для трасляции относительных имен файлов кешированных стилях.
  def self.relative_to_dir(abspath, dirname)
    where = abspath.index(dirname)
    where ? abspath[where + dirname.length..-1] : abspath
  end
end