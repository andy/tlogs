require 'singleton'

module Tlogs
  module Domains
    class Configuration
      include Singleton

      def initialize
        @domains = YAML.load_file(File.join(RAILS_ROOT, 'config/tlogs/domains.yml')) rescue {}
      end
    
      def options_for(name, request)
        name = name.dup.gsub(/^www\./, '') if name.starts_with?('www.')

        domain = @domains.has_key?(name) ? name : @domains.first[0]
        options = @domains.has_key?(name) ? @domains[name] : @domains.first[1]

        Tlogs::Domains::Options.new domain, options.merge(:protocol => request.try(:protocol), :port => request.try(:port))
      end
      
      def default
        options_for(@domains.keys.first, nil)
      end
      
      def domains
        @domains.keys
      end
    end

    class Options
      attr_reader :domain, :name, :url, :protocol, :port, :host

      def initialize(domain, options = {})
        @domain = domain
        @options = options.symbolize_keys

        @protocol = @options[:protocol] || 'http://'
        @port = @options[:port] || 80

        @name = @options[:name] || 'tlogs service'
        @url = "#{protocol}#{domain_with_port}"
      end
      
      def port_postfix
        @port == 80 ? '' : ":#{@port}"
      end
      
      def domain_with_port
        @domain + port_postfix
      end
    
      def is_inline?
        @options[:users] == 'inline'
      end
    
      def is_external?
        !is_inline?
      end
      
      # возвращает полный урл до пользователя сервиса
      def user_url(name)
        if self.is_inline?
          # puts "service::user_url(#{name}, #{@url})"
          @url + "/users/#{name}"
        else
          "#{protocol}#{name}.#{domain_with_port}"
        end
      end
      
    end
  end
end

# Singleton
Tlogs::Domains::CONFIGURATION = Tlogs::Domains::Configuration.instance