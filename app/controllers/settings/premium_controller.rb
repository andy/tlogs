class Settings::PremiumController < ApplicationController
  before_filter :require_current_user, :current_user_eq_current_site
  before_filter :require_confirmed_current_user

  protect_from_forgery

  helper :settings
  layout "settings"
  
end