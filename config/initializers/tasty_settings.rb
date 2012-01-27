begin
  ::SETTINGS = YAML.load_file(File.join(Rails.root, 'config/settings.yml')).symbolize_keys!
rescue
  puts 'Tasty settings file (config/settings.yml) is missing'
  exit
end