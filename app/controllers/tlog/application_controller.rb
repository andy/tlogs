class Tlog::ApplicationController < ApplicationController
  before_filter :require_current_site, :require_confirmed_current_user, :require_confirmed_current_site
  
  
end