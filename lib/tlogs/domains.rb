require 'singleton'

module Tlogs
  module Domains
    class Configuration
      include Singleton

      def initialize
        @domains = YAML.load_file(File.join(RAILS_ROOT, 'config/tlogs/domains.yml')) rescue {}
      end
    
      def options_for(name)
        domain = @domains.has_key?(name) ? name : @domains.first[0]
        options = @domains.has_key?(name) ? @domains[name] : @domains.first[1]
          
        Tlogs::Domains::Options.new domain, options
      end
    end

    class Options
      attr_reader :domain, :name, :url

      def initialize(domain, options)
        @domain = domain
        @options = options.symbolize_keys

        @name = @options[:name] || 'tlogs service'
        @url = @options[:url] || "http://www.#{domain}"
      end
    
      def is_inline?
        @options[:users] == 'inline'
      end
    
      def is_external?
        !is_inline?
      end
    end
  end
end

# Singleton
Tlogs::Domains::CONFIGURATION = Tlogs::Domains::Configuration.instance