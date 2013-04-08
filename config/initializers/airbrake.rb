Airbrake.configure do |config|
  config.api_key = '80f689a37ac40bbf38e841ad2d93a255'

  config.ignore_by_filter do |exception_data|
    exception_data.error_message =~ /ActionController::UnknownHttpMethod: PROPFIND/
  end
end
