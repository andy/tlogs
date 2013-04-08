require 'singleton'

module Tlogs
  module Domains
    class Configuration
      include Singleton

      def initialize
        @domains = YAML.load_file(File.join(RAILS_ROOT, 'config/tlogs/domains.yml')) rescue {}
      end

      def options_for(name, request)
        name = name[4..-1] if name.starts_with?('www.')
        domain = nil

        # in case of ip address
        if name =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
          domain = name if @domains.has_key?(name)
        else
          name.split('.').size.times do |length|
            domain = name.split('.', length).last
            break if @domains.has_key?(domain)

            domain = nil
          end
        end

        domain = @domains.keys.first if domain.nil?

        options = @domains[domain]
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
      attr_reader :domain, :name, :url, :protocol, :port, :host, :mobile

      def initialize(domain, options = {})
        @domain = domain
        @options = options.symbolize_keys

        @protocol = @options[:protocol] || 'http://'
        @port = @options[:port] || 80

        @name = @options[:name] || 'tlogs'
        @url = "#{protocol}#{domain_prefix}#{domain_with_port}"
      end

      def domain_prefix
        # is_inline? ? '' : 'www.'
        ''
      end

      def port_postfix
        @port == 80 ? '' : ":#{@port}"
      end

      def domain_with_port
        @domain + port_postfix
      end

      def is_mobile?
        !!@options[:mobile]
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

      def logo(style = nil)
        @options[:logo] || "logos/default#{style ? "_#{style}" : ''}.png"
      end

      # Домен для добавления глобальной куки
      def cookie_domain
        is_inline? ? @domain : ('.' + @domain)
      end
    end
  end
end

# Singleton
Tlogs::Domains::CONFIGURATION = Tlogs::Domains::Configuration.instance
