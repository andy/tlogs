namespace :cache do
  desc 'Clear app cache'
  task :clear => :environment do
    Rails.cache.clear
  end
end
