class Settings::PremiumController < ApplicationController
  before_filter :require_current_user, :require_owner
  before_filter :require_confirmed_current_user

  protect_from_forgery

  helper :settings
  layout "settings"

  def index
    @accounts = User.find(current_site.linked_with)
    
    render :action => is_premium? ? :index : :about
  end
  
  def about
  end
  
  def link
    if request.post?
      @user = User.authenticate(params[:email], params[:password])
      
      if @user
        current_site.link_with(@user)
        
        render :json => true
      else
        render :json => false
      end
    else
      render :layout => false
    end
  end
  
  def unlink
    render :nothing => true and return unless request.post?

    @user = User.find(params[:id])
    current_site.unlink_from(@user) if @user
    
    render :update do |page|
      page.visual_effect :highlight, "t-accounts-link-#{@user.id}", :duration => 0.3
      page.visual_effect :fade, "t-accounts-link-#{@user.id}", :duration => 0.3
    end
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
  
  def account_link
    render :nothing => true and return false unless request.post?

    @user = User.authenticate(params[:email], params[:password])
    if @user.nil?
    elsif @user.is_openid?
      
    else
      current_site.link_with(@user)
      
      Emailer.deliver_linked_with(current_service, current_site, @user)
      
      render :json => true
    end
  end
  
  def account_unlink
    render :nothing => true and return false unless request.post?
    
    current_site.unlink_from(@user)
    
    render :json => true
  end
  
  def sms_update
    render :nothing => true and return false unless request.post?

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