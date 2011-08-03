namespace :assets do
  desc "Переклеить стили и скрипты и положить их во временную папку"
  task :glue => :environment do
    [AssetGluer::StylesheetFile.temp_cache_dir, AssetGluer::JavascriptFile.temp_cache_dir].each do |temp_dir|
      Dir.mkdir(temp_dir) if not File.exists?(temp_dir)
    end
    
    TASTY_ASSETS[:stylesheets].each do |package, files|
      output = AssetGluer::StylesheetFile.glue(files)
      File.open(File.join(AssetGluer::StylesheetFile.temp_cache_dir, package + '.css'), 'w') { |f| f.write(output) }
    end

    TASTY_ASSETS[:javascripts].each do |package, files|
      output = AssetGluer::JavascriptFile.glue(files)
      File.open(File.join(AssetGluer::JavascriptFile.temp_cache_dir, package + '.js'), 'w') { |f| f.write(output) }
    end
  end
  
  desc "Скопировать склеенные файлы в рабочие директории"
  task :install do
    # system "cd #{Rails.root}/public && rm -f stylesheets/cache/*.css javascripts/cache/*.js"
    system "cd #{Rails.root} && mkdir -p public/stylesheets/cache public/javascripts/cache"
    system "cd #{Rails.root}/public && cp -vf stylesheets/cache-tmp/*.css stylesheets/cache/"
    system "cd #{Rails.root}/public && cp -vf javascripts/cache-tmp/*.js javascripts/cache/"
  end
end