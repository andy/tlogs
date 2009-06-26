# map properly for developer-environment
# ActionController::Base.asset_host = Proc.new do |source, request|
#   protocol = request.protocol
#   host = request.host
#   
#   host = "assets#{source.hash % 4}.mmm-tasty.ru" if host != 'localhost'
#   
#   "#{protocol}#{host}#{request.port == 80 ? '' : ":#{request.port}"}"
# end