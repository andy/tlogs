begin
  ::SETTINGS = YAML.load_file(File.join(RAILS_ROOT, 'config/settings.yml')).symbolize_keys!
rescue
  puts 'Tasty settings file (config/settings.yml) is missing'
  exit
end
