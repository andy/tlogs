namespace :assets do
  desc "Переклеить стили и скрипты и положить их во временную папку"
  task :glue => :environment do

    [AssetGluer::StylesheetFile.temp_cache_dir, AssetGluer::JavascriptFile.temp_cache_dir].each do |temp_dir|
      Dir.mkdir(temp_dir) if not File.exists?(temp_dir)
    end
    
    style_definitions = GROUPPED_STYLESHEETS
    style_definitions.each do |style_name, file_names|
      file_names.each do |variant, file_name|
        stylesheet_file = AssetGluer::StylesheetFile.glue_files(file_name + ".css")
        cached_file_name = style_name + (variant == "default" ? "" : ".#{variant}" ) + ".css"
        File.open(File.join(AssetGluer::StylesheetFile.temp_cache_dir, cached_file_name), 'w') do |f|
          f.write(stylesheet_file)
        end
      end
    end

    script_definitions = GROUPPED_JAVASCRIPTS
    script_definitions.each do |script_name, file_names|
      javascript_file = AssetGluer::JavascriptFile.glue_files(file_names.map{|file_name| file_name + ".js" })
      cached_file_name = script_name + ".js"
      File.open(File.join(AssetGluer::JavascriptFile.temp_cache_dir, cached_file_name), 'w') do |f|
        f.write(javascript_file)
      end
    end
    
  end
end