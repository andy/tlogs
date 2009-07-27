#!/usr/bin/env ruby
require "config/environment"

use Rails::Rack::LogTailer
use Rack::AssetPath
use Rails::Rack::Static
run ActionController::Dispatcher.new
