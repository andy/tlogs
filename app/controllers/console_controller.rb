class ConsoleController < ApplicationController
  before_filter :require_current_user

  before_filter :require_moderator

  protect_from_forgery

  layout 'console'

  helper :console
end
