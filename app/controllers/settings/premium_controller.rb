class Settings::PremiumController < ApplicationController
  before_filter :require_current_user, :require_owner
  before_filter :require_confirmed_current_user

  protect_from_forgery

  helper :settings
  layout "settings"

  def index
    render :action => is_premium? ? :index : :about
  end
  
  def about
  end
  
  def history
    @invoices = current_site.invoices.paginate :page => params[:page], :per_page => 15, :order => 'created_at DESC'
  end
  
  def choose
    render :layout => false
  end
end