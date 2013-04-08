require 'singleton'

module Tlogs
  class Session
    include Singleton

    DEFAULT_SESSION_OPTIONS = {
      'key' => 's',
      'secret' => '4f9e6ec68c82631a58f9857faf1ee8527e5513c251a3abe062443d947c5730ce0c3ac0ee20a67a4c854e6bae7672805f628100fa2e81eb43079156e2a20eda6f'
    }

    def initialize
      @config = DEFAULT_SESSION_OPTIONS.dup
      @config.merge! YAML.load_file(File.join(RAILS_ROOT, 'config', 'tlogs', 'session.yml'))
    end

    def key
      @config['key']
    end

    def secret
      @config['secret']
    end
  end
end

Tlogs::SESSION = Tlogs::Session.instance
