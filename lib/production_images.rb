module ProductionImages
  # Перехватывает отсутствующие картинки и пытается слить их с assets.mmm-tasty.ru
  def self.add_mongrel_images
    return unless defined?(Mongrel)
    return if Mongrel.instance_variable_get('@add_mongrel_images')
    Mongrel.instance_variable_set('@add_mongrel_images', true)
    Mongrel::DirHandler.class_eval do
      alias_method :can_serve_without_images, :can_serve
      def can_serve(path_info)
        if path_info =~ /\/([\d]{10})\/(.*)$/
          path_info = "/#{$2}"
        end
        req_path = Mongrel::HttpRequest.unescape(path_info)
        if req_path.index("/uc/") 
          if !File.exists?(@path + req_path)
            FileUtils.mkdir_p(File.dirname(@path + req_path))
            `curl 'http://assets0.mmm-tasty.ru#{req_path}' -o '#{@path + req_path}' &`
          end
          return @path + req_path
        end
        can_serve_without_images(path_info)
      end
    end
  end
  
  def self.included(base)
    add_mongrel_images if RAILS_ENV == "development"
  end
end