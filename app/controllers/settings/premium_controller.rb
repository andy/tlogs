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
    @countries    = SmsonlineInvoice.countries_for_select
    @qiwi_options = QiwiInvoice.options

    # preferences
    @pref_method  = current_site.invoices.successful.last.pref_key
    @pref_sms     = SmsonlineInvoice.for_user(current_site).successful.last.try(:pref_options)
    @pref_qiwi    = QiwiInvoice.for_user(current_site).successful.last.try(:pref_options)

    render :layout => false
  end
  
  def sms_update
    last_id   = params[:last_id].to_s || 0
    @invoices = SmsonlineInvoice.for_user(current_site).successful.all(:conditions => "invoices.id > #{last_id}")
    
    render :json => @invoices.map { |i| { :id => i.id, :summary => i.summary } }
  end
  
  def qiwi_init_bill
    render :nothing => true and return false unless request.post?
   
    phone   = params[:phone].gsub(/[^0-9]/, '')[0..10]
    user    = current_site
    option  = QiwiInvoice.options_for(params[:option])
    
    @invoice = QiwiInvoice.create!(:user      => user,
                                   :state     => 'pending',
                                   :amount    => option.amount,
                                   :revenue   => option.amount,
                                   :days      => option.days,
                                   :metadata  => HashWithIndifferentAccess.new(:option => option.name,
                                                                              :protocol => 'html',
                                                                              :phone => phone
                                                                             )
                                  )
    
    render :json => @invoice.to_json
  end
end