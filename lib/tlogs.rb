require 'singleton'

module Tlogs
  # Настройки сессии, берутся из config/tlogs/session.yml
  class SessionConfiguration
    include Singleton
    
    attr_accessor :config

    def initialize
      self.config = YAML.load_file(File.join(RAILS_ROOT, 'config', 'tlogs', 'session.yml')).symbolize_keys rescue {}
    end

    def key
      self.config[:key] || "tlogs-#{RAILS_ENV.first}"
    end
    
    def secret
      self.config[:secret] || '4f9e6ec68c82631a58f9857faf1ee8527e5513c251a3abe062443d947c5730ce0c3ac0ee20a67a4c854e6bae7672805f628100fa2e81eb43079156e2a20eda6f'
    end
  end
end

Tlogs::SESSION_CONFIGURATION = Tlogs::SessionConfiguration.instance
