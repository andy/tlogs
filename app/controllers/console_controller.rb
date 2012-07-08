class ConsoleController < ApplicationController
  before_filter :require_current_user
  
  before_filter :require_admin
  
  layout 'console'
  
  helper :console
end