Haml::Template.options[:format] = :html5
Haml::Template.options[:ugly] = true if Rails.env.production?